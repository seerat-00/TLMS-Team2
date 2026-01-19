//
//  LearnerLessonPlaceholderView.swift
//  TLMS-project-main
//
//  Created by Chehak on 19/01/26.
//

import Foundation
import SwiftUI

struct LearnerLessonPlaceholderView: View {
    let lesson: Lesson

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: lesson.type.icon)
                .font(.system(size: 50))
                .foregroundColor(.blue)

            Text(lesson.title)
                .font(.title2.bold())

            Text("\(lesson.type.rawValue) content coming next")
                .foregroundColor(.secondary)
        }
        .padding()
        .navigationTitle("Lesson")
        .navigationBarTitleDisplayMode(.inline)
    }
}
