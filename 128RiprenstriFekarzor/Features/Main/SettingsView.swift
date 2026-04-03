//
//  SettingsView.swift
//  128RiprenstriFekarzor
//

import StoreKit
import SwiftUI
import UIKit

struct SettingsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("About this build")
                    .font(.body)
                    .foregroundStyle(Color.appTextSecondary)

                VStack(spacing: 12) {
                    settingsRow(title: "Rate us", systemImage: "star.fill") {
                        rateApp()
                    }
                    settingsRow(title: "Privacy Policy", systemImage: "hand.raised.fill") {
                        openPolicy(link: .privacyPolicy)
                    }
                    settingsRow(title: "Terms of Use", systemImage: "doc.text.fill") {
                        openPolicy(link: .termsOfUse)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .background(Color.clear)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Settings")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)
                    .shadow(color: Color.appPrimary.opacity(0.18), radius: 8, y: 0)
            }
        }
    }

    private func openPolicy(link: AppExternalLink) {
        if let url = link.url {
            UIApplication.shared.open(url)
        }
    }

    private func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }

    private func settingsRow(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.appAccent)
                    .frame(width: 28, alignment: .center)
                Text(title)
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
    }
}
