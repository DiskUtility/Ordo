//
//  DetentSheetPresenter.swift
//  Planner
//
//  Created by Vedang Patel on 2026-02-22.
//

import SwiftUI

struct DetentSheetPresenter<SheetContent: View>: ViewModifier {
    private static var peekDetent: PresentationDetent {
        .height(120)
    }

    @Binding var isPresented: Bool
    @State private var selectedDetent: PresentationDetent = Self.peekDetent
    @State private var sheetInteraction: PresentationContentInteraction = .resizes

    @ViewBuilder let sheetContent: SheetContent

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                ScrollView {
                    sheetContent
                }
                .presentationDetents([Self.peekDetent, .medium, .large], selection: $selectedDetent)
                .presentationContentInteraction(sheetInteraction)
                .presentationBackgroundInteraction(.enabled)
                .interactiveDismissDisabled()
            }
            .onChange(of: selectedDetent) { _, newValue in
                sheetInteraction = (newValue == Self.peekDetent) ? .resizes : .scrolls
            }
    }
}

extension View {
    func detentSheet<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(DetentSheetPresenter(isPresented: isPresented, sheetContent: content))
    }
}
