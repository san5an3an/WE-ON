//
//  ExpenditureDetailView.swift
//  WE-ON
//
//  Created by SAN on 10/2/26.
//

import SwiftUI

// 지출 한 건의 상세 정보와 수정, 삭제 화면 구성
struct ExpenditureDetailView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var expenditure: Expenditure
  @State private var isEditPresented = false
  @State private var isDeleteConfirming = false
  @State private var isDeleting = false
  @State private var error: WEONError?
  private let dependencies: AppDependencies
  
  init(expenditure: Expenditure, dependencies: AppDependencies = .shared) {
    _expenditure = State(initialValue: expenditure)
    self.dependencies = dependencies
  }
  
  var body: some View {
    List {
      Section {
        VStack(spacing: Spacing.s) {
          Text(expenditure.storeName)
            .font(.seed(16, weight: .bold, relativeTo: .headline))
            .foregroundStyle(.secondary)
          Text("-\(expenditure.price.wonText)")
            .font(.seed(34, weight: .bold, relativeTo: .largeTitle))
            .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.l)
      }
      Section {
        LabeledContent("날짜", value: expenditure.date.formatted(.dateTime.year().month().day().weekday(.wide)))
        LabeledContent("가게명", value: expenditure.storeName)
        LabeledContent("메모", value: expenditure.memo.isEmpty ? "-" : expenditure.memo)
        LabeledContent("지출 번호", value: "\(expenditure.id)")
      }
      .font(.seed(15, relativeTo: .body))
      Section {
        Button("지출 내역 삭제", role: .destructive) { isDeleteConfirming = true }
          .frame(maxWidth: .infinity)
      }
    }
    .navigationTitle("지출 상세")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      Button("수정") { isEditPresented = true }
    }
    .sheet(isPresented: $isEditPresented) {
      ExpenditureFormView(editing: expenditure) {
        dismiss()
      }
    }
    .alert("지출 내역 삭제", isPresented: $isDeleteConfirming) {
      Button("취소", role: .cancel) {}
      Button("삭제하기", role: .destructive) {Task{await delete()}}
    } message: {
      Text("해당 작업은 되돌릴 수 없어요.\n정말로 이 지출내역을 삭제하시겠어요?")
    }
    .loadingOverlay(isDeleting)
    .errorAlert($error)
  }
  
  // 지출 삭제 후 이전 화면으로 이동
  private func delete() async {
    isDeleting = true
    defer { isDeleting = false }
    do {
      try await dependencies.account.deleteExpenditure(id: expenditure.id)
      dismiss()
    } catch {
      self.error = WEONError.wrap(error)
    }
  }
}
