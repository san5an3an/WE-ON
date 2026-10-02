//
//  AccountSettingView.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import SwiftUI

struct AccountSettingView: View {
    @State private var viewModel = AccountSettingViewModel()
    @FocusState private var isBudgetFocused: Bool

    var body: some View {
        @Bindable var viewModel = viewModel
        Form {
            Section {
                HStack {
                    TextField("예산 금액", text: budgetText)
                        .keyboardType(.numberPad)
                        .focused($isBudgetFocused)
                        .monospacedDigit()
                    Text("원")
                        .foregroundStyle(.secondary)
                }
                Button("예산 저장") {
                    isBudgetFocused = false
                    Task { await viewModel.saveBudget() }
                }
                .disabled(!viewModel.canSaveBudget)
            } header: {
                Text("이번 달 예산")
            } footer: {
                Text("한 달 동안 쓸 식비 예산이에요. 가계부 요약의 잔액 계산에 사용돼요.")
            }

            Section {
                Toggle("지출 내역 추가 알림 받기", isOn: Binding(
                    get: { viewModel.isAlarmOn },
                    set: { isOn in Task { await viewModel.setAlarm(isOn) } }
                ))
            } footer: {
                Text("지출을 기록하는 걸 잊지 않도록 알림을 보내 드려요.")
            }
        }
        .font(.seed(16, relativeTo: .body))
        .navigationTitle("가계부 설정")
        .navigationBarTitleDisplayMode(.inline)
        .loadingOverlay(viewModel.isLoading)
        .errorAlert($viewModel.error)
        .alert("저장 완료", isPresented: Binding(get: { viewModel.message != nil }, set: { if !$0 { viewModel.message = nil } })) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(viewModel.message ?? "")
        }
        .task { await viewModel.load() }
    }

    private var budgetText: Binding<String> {
        Binding(
            get: { viewModel.budget.map { $0.formatted(.number.grouping(.automatic)) } ?? "" },
            set: { viewModel.updateBudget(from: $0) }
        )
    }
}
