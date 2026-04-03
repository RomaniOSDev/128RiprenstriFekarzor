//
//  ActivitiesFlowView.swift
//  128RiprenstriFekarzor
//

import SwiftUI

struct ActivitiesFlowView: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ActivityGalleryView(path: $path)
                .navigationDestination(for: FlowStep.self) { step in
                    switch step {
                    case .pickLevels(let activity):
                        LevelSelectionView(activity: activity, path: $path)
                    case .playCascade(let activity, let difficulty, let level):
                        ColorCascadeSessionView(activity: activity, difficulty: difficulty, level: level, path: $path)
                    case .playShape(let activity, let difficulty, let level):
                        ShapeShuffleSessionView(activity: activity, difficulty: difficulty, level: level, path: $path)
                    case .playPattern(let activity, let difficulty, let level):
                        PatternPlaySessionView(activity: activity, difficulty: difficulty, level: level, path: $path)
                    case .wrapUp(let payload):
                        ActivityResultView(payload: payload, path: $path)
                    }
                }
        }
    }
}

struct ActivityGalleryView: View {
    @Binding var path: NavigationPath

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Pick a flow")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)
                    .appHeadingDepth()
                    .padding(.top, 8)

                Text("Each route keeps its own star map and unlock rhythm.")
                    .font(.body)
                    .foregroundStyle(Color.appTextSecondary)

                ForEach(CasualActivity.allCases) { activity in
                    Button {
                        path.append(FlowStep.pickLevels(activity))
                    } label: {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(activity.title)
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(Color.appTextPrimary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(Color.appAccent)
                            }
                            Text(activity.blurb)
                                .font(.subheadline)
                                .foregroundStyle(Color.appTextSecondary)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .appElevatedSurface(cornerRadius: 18)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .background(Color.clear)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Activities")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)
                    .shadow(color: Color.appPrimary.opacity(0.18), radius: 8, y: 0)
            }
        }
    }
}
