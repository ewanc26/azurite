//
//  PDSResolver.swift
//  azurite
//
//  Created by Ewan Croft on 28/02/2026.
//

import Foundation

/// Resolves an AT Protocol handle to its Personal Data Server (PDS) endpoint.
///
/// Resolution follows the same strategy as the website's `agents.ts`:
///   1. Resolve the handle to a DID via the HTTPS well-known endpoint
///      (`https://<handle>/.well-known/atproto-did`), falling back to a
///      `com.atproto.identity.resolveHandle` XRPC call against the public AppView.
///   2. Resolve the DID → PDS using Slingshot (`slingshot.microcosm.blue`),
///      which returns a compact `{ did, pds }` mini-doc in one round-trip.
enum PDSResolver {

    enum ResolutionError: LocalizedError {
        case invalidHandle
        case didNotFound
        case slingshotFailed(Int)
        case pdsNotFoundInDocument

        var errorDescription: String? {
            switch self {
            case .invalidHandle:              return "The handle doesn't look valid."
            case .didNotFound:               return "Couldn't resolve a DID for this handle."
            case .slingshotFailed(let code): return "Identity resolution failed (HTTP \(code))."
            case .pdsNotFoundInDocument:     return "No PDS endpoint found for this DID."
            }
        }
    }

    // MARK: - Public API

    /// Returns the PDS base URL (e.g. `https://bsky.social`) for the given handle.
    static func resolvePDS(for handle: String) async throws -> String {
        let handle = handle.hasPrefix("@") ? String(handle.dropFirst()) : handle
        let did = try await resolveDID(for: handle)
        return try await slingshotPDS(for: did)
    }

    // MARK: - Step 1: Handle → DID

    private static func resolveDID(for handle: String) async throws -> String {
        guard handle.contains(".") else { throw ResolutionError.invalidHandle }

        // First try: HTTPS well-known on the handle's own domain
        if let did = try? await fetchDIDFromWellKnown(handle: handle) {
            return did
        }

        // Fallback: resolveHandle XRPC via the public Bluesky AppView
        return try await fetchDIDFromXRPC(handle: handle)
    }

    private static func fetchDIDFromWellKnown(handle: String) async throws -> String {
        guard let url = URL(string: "https://\(handle)/.well-known/atproto-did") else {
            throw ResolutionError.invalidHandle
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw ResolutionError.didNotFound
        }
        let did = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard did.hasPrefix("did:") else { throw ResolutionError.didNotFound }
        return did
    }

    private static func fetchDIDFromXRPC(handle: String) async throws -> String {
        var components = URLComponents(string: "https://public.api.bsky.app/xrpc/com.atproto.identity.resolveHandle")!
        components.queryItems = [URLQueryItem(name: "handle", value: handle)]
        guard let url = components.url else { throw ResolutionError.invalidHandle }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw ResolutionError.didNotFound
        }

        struct XRPCResponse: Decodable { let did: String }
        return try JSONDecoder().decode(XRPCResponse.self, from: data).did
    }

    // MARK: - Step 2: DID → PDS via Slingshot

    private static func slingshotPDS(for did: String) async throws -> String {
        var components = URLComponents(string: "https://slingshot.microcosm.blue/xrpc/com.bad-example.identity.resolveMiniDoc")!
        components.queryItems = [URLQueryItem(name: "identifier", value: did)]
        guard let url = components.url else { throw ResolutionError.pdsNotFoundInDocument }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let status = (response as? HTTPURLResponse)?.statusCode, status == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw ResolutionError.slingshotFailed(code)
        }

        struct MiniDoc: Decodable { let did: String; let pds: String }
        let doc = try JSONDecoder().decode(MiniDoc.self, from: data)
        guard !doc.pds.isEmpty else { throw ResolutionError.pdsNotFoundInDocument }
        return doc.pds
    }
}
