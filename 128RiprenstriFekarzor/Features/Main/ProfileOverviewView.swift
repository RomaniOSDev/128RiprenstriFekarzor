//
//  ProfileOverviewView.swift
//  128RiprenstriFekarzor
//

import SwiftUI

struct ProfileOverviewView: View {
    @EnvironmentObject private var progress: GameProgressStore
    @State private var showResetConfirm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Progress snapshot")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(Color.appTextPrimary)
                        .appHeadingDepth()

                    Text("Track how often you return, how long you stay, and which milestones you have unlocked.")
                        .font(.body)
                        .foregroundStyle(Color.appTextSecondary)

                    VStack(spacing: 12) {
                        statBlock(title: "Combined stars", value: "\(progress.totalStarsAcrossApp())")
                        statBlock(title: "Total play time", value: formatTime(progress.totalPlaySeconds()))
                        statBlock(title: "Activities completed (sessions)", value: "\(progress.totalSessionsPlayed())")
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Rewards")
                            .font(.headline)
                            .foregroundStyle(Color.appTextPrimary)
                        Text("Open the Rewards tab to see every badge, locked goals, and your vault progress.")
                            .font(.subheadline)
                            .foregroundStyle(Color.appTextSecondary)
                        HStack {
                            Text("Unlocked")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.appTextSecondary)
                            Spacer()
                            Text("\(progress.unlockedAchievementCount()) / \(progress.totalAchievementCount())")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color.appAccent)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .padding(14)
                        .appInsetPanel(cornerRadius: 14)
                    }
                    .padding(.top, 4)

                    NavigationLink {
                        SettingsView()
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "gearshape.fill")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(Color.appAccent)
                                .frame(width: 28, alignment: .center)
                            Text("Settings")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(Color.appTextPrimary)
                            Spacer(minLength: 8)
                            Image(systemName: "chevron.right")
                                .font(.footnote.weight(.bold))
                                .foregroundStyle(Color.appTextSecondary)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .appElevatedSurface(cornerRadius: 16)
                    }
                    .buttonStyle(.plain)

                    SecondaryGameButton(title: "Reset All Progress") {
                        showResetConfirm = true
                    }
                    .padding(.top, 12)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
            .background(Color.clear)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Profile")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.appTextPrimary)
                        .shadow(color: Color.appPrimary.opacity(0.18), radius: 8, y: 0)
                }
            }
            .alert("Reset everything?", isPresented: $showResetConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    progress.resetAll()
                }
            } message: {
                Text("This clears stars, unlocks, statistics, and brings back the introductory walkthrough.")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .gameProgressDidReset)) { _ in
            showResetConfirm = false
        }
    }

    private func statBlock(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(Color.appTextSecondary)
            Spacer()
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.appAccent)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(16)
        .appElevatedSurface(cornerRadius: 16)
    }

    private func formatTime(_ t: TimeInterval) -> String {
        let h = Int(t) / 3600
        let m = (Int(t) % 3600) / 60
        let s = Int(t) % 60
        if h > 0 {
            return String(format: "%dh %02dm", h, m)
        }
        return String(format: "%dm %02ds", m, s)
    }
}
