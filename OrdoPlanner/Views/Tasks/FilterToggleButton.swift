//
//  FilterToggleButton.swift
//  Planner
//
//  Created by Vedang Patel on 2026-02-22.
//

import SwiftUI

struct FilterToggleButton<FilterOptions: View>: View {
    @Binding var isFilterEnabled: Bool
    @Binding var isShowingSheet: Bool
    let filteredByText: String
    @ViewBuilder let filterOptionsView: FilterOptions

    init(
        isFilterEnabled: Binding<Bool>,
        isShowingSheet: Binding<Bool> = .constant(false),
        filteredByText: String,
        @ViewBuilder filterOptionsView: () -> FilterOptions
    ) {
        _isFilterEnabled = isFilterEnabled
        _isShowingSheet = isShowingSheet
        self.filteredByText = filteredByText
        self.filterOptionsView = filterOptionsView()
    }

    var body: some View {
        Toggle(
            "Toggle Filter",
            systemImage: "line.3.horizontal.decrease",
            isOn: $isFilterEnabled.animation(.spring(response: 0.28, dampingFraction: 0.88))
        )
        .labelsHidden()

        if isFilterEnabled {
            Button {
                isShowingSheet = true
            } label: {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Filtered by")
                        .font(.caption.weight(.semibold))
                    Text("\(filteredByText) \(Image(systemName: "chevron.down"))")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.tint)
                        .lineLimit(1)
                }
                .padding(.trailing, 4)
                .frame(maxWidth: 160, alignment: .leading)
            }
            .detentSheet(isPresented: $isShowingSheet) {
                filterOptionsView
            }
        }
    }
}
