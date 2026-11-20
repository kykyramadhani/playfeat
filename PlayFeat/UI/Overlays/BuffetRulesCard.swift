import SwiftUI

struct BuffetRulesCard: View {
    @Environment(\.scenePhase) private var scenePhase
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            NoticeCard {
                VStack(spacing: 23) {
                    HStack(spacing: 18) {
                        ForEach(0..<MarathonFlow.lostCustomersToEnd, id: \.self) { _ in
                            Image("LostCustomerCross")
                                .resizable()
                                .frame(width: 43, height: 43)
                                .foregroundStyle(Color.lostCustomerMark)
                        }
                    }
                    .accessibilityHidden(true)
                    Text("\(MarathonFlow.lostCustomersToEnd) lost customers end the run")
                        .font(.atkinson(size: 38, weight: .bold))
                        .accessibilityAddTraits(.isHeader)
                    HStack(spacing: 46) {
                        stat("Points", icon: "star.fill")
                        stat("Tips", icon: "dollarsign.circle.fill")
                    }
                    .font(.atkinson(size: 25, weight: .bold))
                    RaisedTextButton(title: "Continue", palette: .start, action: onContinue)
                        .fixedSize()
                }
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.purple900)
                .padding(.vertical, 45)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onContinue)
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.default, onContinue)
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            do { try await Task.sleep(for: .seconds(3)) } catch { return }
            onContinue()
        }
    }

    private func stat(_ title: LocalizedStringKey, icon: String) -> some View {
        VStack(spacing: 5) {
            Label(title, systemImage: icon)
            Text(0, format: .number)
        }
        .accessibilityElement(children: .combine)
    }
}
