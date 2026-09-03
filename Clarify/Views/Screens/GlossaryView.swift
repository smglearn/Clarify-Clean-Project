//
//  GlossaryView.swift
//  Clarify
//
//  A standalone browse view over the entire local JargonGlossary, so
//  the flip-card translator is useful even outside of an active
//  workflow. Uses an adaptive grid so it reflows sensibly at every
//  Dynamic Type size and on every device width.
//
//  A search field and a small "X of Y translated" header were added
//  once the glossary grew past a single screenful (14 terms at launch,
//  35 after the four-company expansion) — browsing alone stops being
//  enough once a list is that long.
//

import SwiftUI

struct GlossaryView: View {
    @Environment(GamificationManager.self) private var gamification
    @State private var searchText = ""

    private let columns = [GridItem(.adaptive(minimum: 160, maximum: 220), spacing: 12)]

    private var filteredTerms: [JargonTerm] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return JargonGlossary.allTerms }
        return JargonGlossary.allTerms.filter {
            $0.term.lowercased().contains(query) || $0.analogy.lowercased().contains(query)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if filteredTerms.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                        .padding(.top, 60)
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        if searchText.isEmpty {
                            translatedProgressHeader
                        }
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(filteredTerms) { term in
                                JargonCardFlip(jargonTerm: term)
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Glossary")
            .searchable(text: $searchText, prompt: "Search terms")
        }
    }

    private var translatedProgressHeader: some View {
        let total = JargonGlossary.allTerms.count
        let flipped = JargonGlossary.allTerms.filter { gamification.flippedTermIDs.contains($0.id) }.count

        return HStack(spacing: 10) {
            Image(systemName: "character.book.closed.fill")
                .foregroundStyle(.indigo)
            Text("\(flipped) of \(total) terms translated")
                .font(.subheadline.weight(.semibold))
            Spacer()
            if flipped < total {
                Text("+3 XP for a new one")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}
