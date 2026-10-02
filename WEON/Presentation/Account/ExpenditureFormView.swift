//
//  ExpenditureFormView.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import SwiftUI

struct ExpenditureFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ExpenditureFormViewModel
    @FocusState private var focusedField: Field?
    private let onSaved: () -> Void

    private enum Field {
        case price
        case store
        case memo
    }

    init(editing: Expenditure?, onSaved: @escaping () -> Void) {
        _viewModel = State(initialValue: ExpenditureFormViewModel(editing: editing))
        self.onSaved = onSaved
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    Text(viewModel.isEditing ? "지출 내역을 수정해 주세요" : "어디서 얼마를 썼나요?")
                        .font(.seed(24, weight: .bold, relativeTo: .title2))
                        .padding(.vertical, Spacing.s)

                    FormField(title: "지출 금액", isFocused: focusedField == .price) {
                        HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                            TextField("0", text: priceText)
                                .keyboardType(.numberPad)
                                .focused($focusedField, equals: .price)
                                .font(.seed(28, weight: .bold, relativeTo: .title))
                                .monospacedDigit()
                            Text("원")
                                .font(.seed(20, weight: .bold, relativeTo: .title3))
                                .foregroundStyle(.secondary)
                        }
                    }
                    FormField(title: "가게명", isFocused: focusedField == .store, text: $viewModel.draft.storeName) {
                        TextField("가게 이름 입력", text: $viewModel.draft.storeName)
                            .focused($focusedField, equals: .store)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .memo }
                    }
                    FormField(title: "메모 (선택)", isFocused: focusedField == .memo, text: $viewModel.draft.memo) {
                        TextField("예: 점심, 친구와 저녁", text: $viewModel.draft.memo)
                            .focused($focusedField, equals: .memo)
                            .submitLabel(.done)
                    }
                    FormField(title: "날짜") {
                        DatePicker("지출 날짜", selection: $viewModel.draft.date, in: ...Date.now, displayedComponents: .date)
                            .labelsHidden()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(Spacing.xl)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.canvas)
            .safeAreaInset(edge: .bottom) {
                Button(viewModel.isEditing ? "수정 완료" : "저장하기") {
                    focusedField = nil
                    Task { await viewModel.submit() }
                }
                .buttonStyle(.primary)
                .disabled(!viewModel.canSubmit)
                .padding(.horizontal, Spacing.xl)
                .padding(.vertical, Spacing.s)
            }
            .navigationTitle(viewModel.isEditing ? "지출 수정" : "지출 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
            }
            .loadingOverlay(viewModel.isSaving)
            .errorAlert($viewModel.error)
            .onChange(of: viewModel.didSave) { _, saved in
                guard saved else { return }
                onSaved()
                dismiss()
            }
            .sensoryFeedback(.success, trigger: viewModel.didSave)
            .onAppear { if !viewModel.isEditing { focusedField = .price } }
        }
        .presentationDetents([.large])
    }

    private var priceText: Binding<String> {
        Binding(
            get: { viewModel.draft.price.map { $0.formatted(.number.grouping(.automatic)) } ?? "" },
            set: { viewModel.updatePrice(from: $0) }
        )
    }
}
