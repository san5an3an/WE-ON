//
//  AccountView.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import SwiftUI

// 가계부 탭, 로그인 전에는 로그인 안내 표시
struct AccountView: View {
    @Environment(SessionStore.self) private var session

    var body: some View {
        Group {
            if session.isSignedIn {
                AccountContentView()
            } else {
                LoginRequiredView(message: "로그인하면 한 달 식비 예산과\n지출 내역을 관리할 수 있어요.")
            }
        }
        .navigationTitle("가계부")
    }
}

// 로그인 후 보이는 월별 가계부 화면 구성
private struct AccountContentView: View {
    @State private var viewModel = AccountViewModel()
    @State private var isAddPresented = false
    // 삭제 확인을 기다리는 지출 보관
    @State private var pendingDelete: Expenditure?

    var body: some View {
        @Bindable var viewModel = viewModel
        List {
            Section {
                monthSwitcher
                BudgetSummaryCard(summary: viewModel.summary, title: "\(viewModel.month.month)월 요약")
            }
            .listRowInsets(EdgeInsets(top: Spacing.s, leading: Spacing.l, bottom: Spacing.s, trailing: Spacing.l))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)

            ForEach(viewModel.groups) { group in
                Section {
                    ForEach(group.items) { expenditure in
                        NavigationLink(value: AppRoute.expenditureDetail(expenditure)) {
                            ExpenditureRow(expenditure: expenditure)
                        }
                        .swipeActions {
                            Button("삭제", systemImage: "trash", role: .destructive) { pendingDelete = expenditure }
                        }
                    }
                } header: {
                    HStack {
                        Text(group.day.formatted(.dateTime.month().day().weekday(.abbreviated)))
                        Spacer()
                        Text("-\(group.total.wonText)")
                            .monospacedDigit()
                    }
                    .font(.seed(13, weight: .bold, relativeTo: .footnote))
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.canvas)
        .overlay(alignment: .bottom) {
            if viewModel.didLoad && viewModel.groups.isEmpty {
                EmptyStateView(title: "지출 내역이 없어요", message: "이번 달 첫 지출을 기록해 보세요.", actionTitle: "지출 추가하기") {
                    isAddPresented = true
                }
                .padding(.bottom, Spacing.xxl)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                NavigationLink(value: AppRoute.accountSetting) {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("가계부 설정")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isAddPresented = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                .accessibilityLabel("지출 추가")
            }
        }
        .sheet(isPresented: $isAddPresented) {
            ExpenditureFormView(editing: nil) {
                Task { await viewModel.load() }
            }
        }
        .confirmationDialog("지출 내역을 삭제할까요?", isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }), titleVisibility: .visible, presenting: pendingDelete) { expenditure in
            Button("삭제", role: .destructive) { Task { await viewModel.delete(expenditure) } }
        }
        .loadingOverlay(viewModel.isLoading)
        .errorAlert($viewModel.error)
        .refreshable { await viewModel.load() }
        .task { await viewModel.load() }
    }

    // 이전 달과 다음 달 이동 버튼 표시
    private var monthSwitcher: some View {
        HStack {
            Button {
                Task { await viewModel.moveMonth(by: -1) }
            } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("이전 달")
            Spacer()
            Text(viewModel.month.title)
                .font(.seed(18, weight: .bold, relativeTo: .headline))
                .contentTransition(.numericText())
            Spacer()
            Button {
                Task { await viewModel.moveMonth(by: 1) }
            } label: {
                Image(systemName: "chevron.right")
                    .frame(width: 44, height: 44)
            }
            .disabled(!viewModel.canMoveForward)
            .accessibilityLabel("다음 달")
        }
        .buttonStyle(.borderless)
        .font(.body.weight(.semibold))
        .padding(.horizontal, Spacing.xs)
        .background(Color.brandSoft, in: Capsule())
    }
}

// 지출 내역 한 줄 표시
struct ExpenditureRow: View {
    let expenditure: Expenditure

    var body: some View {
        HStack(spacing: Spacing.m) {
            Image(systemName: "fork.knife")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.brandText)
                .frame(width: 36, height: 36)
                .background(Color.brandSoft, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(expenditure.storeName)
                    .font(.seed(15, weight: .bold, relativeTo: .body))
                    .lineLimit(1)
                if !expenditure.memo.isEmpty {
                    Text(expenditure.memo)
                        .font(.seed(13, relativeTo: .footnote))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            Text("-\(expenditure.price.wonText)")
                .font(.seed(15, weight: .bold, relativeTo: .body))
                .monospacedDigit()
        }
        .padding(.vertical, 2)
    }
}
