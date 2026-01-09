//
//  QuestionnaireService.swift
//  TLMS-project-main
//
//  Created by Chehak on 08/01/26.
//

import Foundation
import Supabase

final class QuestionnaireService {

    private let supabase = SupabaseClient(
        supabaseURL: URL(string: SupabaseConfig.supabaseURL)!,
        supabaseKey: SupabaseConfig.supabaseAnonKey
    )

    func save(_ response: QuestionnaireResponse) async throws {
        try await supabase
            .from("questionnaire_responses")
            .upsert(
                response.toSupabasePayload(),
                onConflict: "user_id"
            )
            .execute()
    }

    func fetch(userId: String) async throws -> QuestionnaireResponse? {
        let result: [QuestionnaireResponseRow] = try await supabase
            .from("questionnaire_responses")
            .select()
            .eq("user_id", value: userId)
            .limit(1)
            .execute()
            .value

        return result.first?.toModel()
    }
}
