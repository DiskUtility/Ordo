//
//  ContentView.swift
//  Planner
//
//  Created by Vedang Patel on 2026-02-22.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    // Keep this in sync with PlannerRootViewController.
    private let onboardingEnabled = false

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StudentProfile.createdAt) private var profiles: [StudentProfile]
    @State private var hasBootstrapped = false

    var body: some View {
        ZStack {
            if onboardingEnabled, profiles.first == nil {
                OnboardingFlowView()
                    .transition(
                        .asymmetric(
                            insertion: .opacity,
                            removal: .move(edge: .leading).combined(with: .opacity)
                        )
                    )
            } else {
                PlannerTabView(studentLevel: profiles.first?.studentLevel ?? .college)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .opacity
                        )
                    )
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.9), value: profiles.count)
        .task {
            guard !hasBootstrapped else { return }
            hasBootstrapped = true
            DevelopmentBootstrapper.bootstrapIfNeeded(modelContext: modelContext, existingProfiles: profiles)
        }
    }
}

private struct PlannerTabView: View {
    let studentLevel: StudentLevel
    @State private var animateIn = false

    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Today", systemImage: "square.grid.2x2")
                }

            CoursesView(defaultStudentLevel: studentLevel)
                .tabItem {
                    Label("Timeline", systemImage: "books.vertical")
                }

            TasksView()
                .tabItem {
                    Label("Tasks", systemImage: "checklist")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .tint(AppTheme.accent)
        .scaleEffect(animateIn ? 1 : 0.985)
        .opacity(animateIn ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                animateIn = true
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [StudentProfile.self, AcademicTerm.self, Course.self, AssignmentTask.self], inMemory: true)
        .environmentObject(AppServices())
}
