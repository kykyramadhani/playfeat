//
//  SettingsView.swift
//  GetCooking
//
//  The in-game settings popup: sound-effects and music volume, language, and
//  hand mode (with which hand, once one-hand mode is on), plus the pickup
//  gesture. Drawn in the Sunrise popup frame over whatever screen opened it.
//
//  Volumes are stored in UserDefaults under the keys AudioManager reads at
//  launch, and pushed live into AudioManager as the sliders move. Picking a
//  language applies it immediately — see AppLocalization.
//

import SwiftUI

struct SettingsView: View {
    @Environment(AudioManager.self) private var audio

    var onClose: () -> Void

    // MARK: - Persisted settings

    // Defaults mirror AudioManager's own starting values.
    @AppStorage(AudioManager.musicVolumeKey) private var musicVolume: Double = 0.45
    @AppStorage(AudioManager.sfxVolumeKey) private var sfxVolume: Double = 1.0

    @AppStorage(AppLocalization.storageKey) private var language: AppLanguage = .english

    @AppStorage(HandInputModeSetting.isOneHandKey) private var isOneHand = false
    @AppStorage(HandInputModeSetting.preferredHandKey) private var preferredHand: HandSide = .right
    @AppStorage(GripGesture.storageKey) private var grip = GripGesture.defaultGesture

    /// The label gets everything left of the control, so longer labels and
    /// translations fit on one line.
    private static let labelWidth: CGFloat = 259
    private static let controlWidth: CGFloat = 442

    var body: some View {
        SunrisePopupOverlay(title: Text("Settings"), onClose: onClose) {
            VStack(alignment: .leading, spacing: 24) {
                settingRow("Sound Effects", height: VolumeSlider.height) {
                    VolumeSlider(value: $sfxVolume, onEditingEnded: { _ in
                        // A quick tick so the player hears the new level.
                        audio.play(.uiClick)
                    }) { newValue in
                        audio.effectsVolume = Float(newValue)
                    }
                }
                settingRow("Music", height: VolumeSlider.height) {
                    VolumeSlider(value: $musicVolume, onChanged: { newValue in
                        audio.musicVolume = Float(newValue)
                    })
                }
                settingRow("Language", height: SegmentedPill.Size.regular.buttonSize.height) { languageChoice }
                settingRow("Hand-mode", height: SegmentedPill.Size.regular.buttonSize.height) { handModeChoice }
                settingRow("Pickup Gesture", height: SegmentedPill.Size.regular.buttonSize.height) {
                    SegmentedPill(
                        leftTitle: Text("Pinch"),
                        rightTitle: Text("F Pinch"),
                        isRightSelected: Binding(
                            get: { grip == .fPinch },
                            set: { grip = $0 ? .fPinch : .pinch }
                        )
                    )
                }
            }
            .padding(.leading, 51)
            .padding(.top, 55)
            .frame(maxWidth: .infinity, alignment: .leading)
            .sunrisePanel()
        }
    }

    // MARK: - Rows

    private var languageChoice: some View {
        SegmentedPill(
            leftTitle: Text(verbatim: "ENG"),
            rightTitle: Text(verbatim: "IND"),
            isRightSelected: Binding(
                get: { language == .indonesia },
                set: { isIndonesia in
                    let next: AppLanguage = isIndonesia ? .indonesia : .english
                    // Bundle first, stored value second. Writing the
                    // preference is what rebuilds the view tree (see
                    // ContentView's `.id`), and that rebuild has to find the
                    // new strings already in place — the other order redraws
                    // everything in the language being switched away from.
                    AppLocalization.apply(next)
                    language = next
                }
            )
        )
    }

    /// OFF / ON, and once one-hand mode is on, which hand plays.
    private var handModeChoice: some View {
        VStack(alignment: .trailing, spacing: 32) {
            SegmentedPill(leftTitle: Text("OFF"), rightTitle: Text("ON"), isRightSelected: $isOneHand)
            if isOneHand {
                SegmentedPill(
                    leftTitle: Text(HandSide.left.displayName),
                    rightTitle: Text(HandSide.right.displayName),
                    isRightSelected: Binding(
                        get: { preferredHand == .right },
                        set: { preferredHand = $0 ? .right : .left }
                    ),
                    size: .small
                )
            }
        }
    }

    /// One labelled row: the label on the left, centred on the control's
    /// first line (`height`), and the control right-aligned.
    private func settingRow<Control: View>(
        _ title: LocalizedStringKey,
        height: CGFloat,
        @ViewBuilder control: () -> Control
    ) -> some View {
        HStack(alignment: .top, spacing: 0) {
            Text(title)
                .font(.atkinson(size: 24, weight: .bold))
                .foregroundStyle(.black)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .frame(width: Self.labelWidth, height: height, alignment: .leading)
            control()
                .frame(width: Self.controlWidth, alignment: .trailing)
        }
    }
}

// MARK: - Volume slider

/// A rounded, draggable volume bar: grey track, green fill, purple thumb.
/// `value` is 0...1. `onChanged` fires continuously as the player drags;
/// `onEditingEnded` fires once when they let go.
struct VolumeSlider: View {
    @Binding var value: Double
    var onEditingEnded: ((Double) -> Void)? = nil
    var onChanged: ((Double) -> Void)? = nil

    static let height: CGFloat = 38
    private let trackHeight: CGFloat = 29.2
    private let thumbSize = CGSize(width: 26.5, height: VolumeSlider.height)

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let clamped = min(max(value, 0), 1)

            // Keep the thumb fully on the track at both ends.
            let travel = max(width - thumbSize.width, 0)
            let thumbX = travel * clamped

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 10.6)
                    .fill(Color(white: 124 / 255).opacity(0.2))
                    .frame(height: trackHeight)

                RoundedRectangle(cornerRadius: 10.6)
                    .fill(Color.green300)
                    .frame(width: thumbX + thumbSize.width / 2, height: trackHeight)

                Capsule()
                    .fill(Color.purple600)
                    .frame(width: thumbSize.width, height: thumbSize.height)
                    .offset(x: thumbX)
            }
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let x = gesture.location.x - thumbSize.width / 2
                        let newValue = travel > 0 ? Double(x / travel) : 0
                        let bounded = min(max(newValue, 0), 1)
                        value = bounded
                        onChanged?(bounded)
                    }
                    .onEnded { _ in onEditingEnded?(value) }
            )
        }
        .frame(height: thumbSize.height)
    }
}

// MARK: - Two-option toggle

/// Two chunky buttons side by side, the chosen one filled magenta. The right
/// option is selected when `isRightSelected` is true.
struct SegmentedPill: View {
    enum Size {
        case regular, small

        var buttonSize: CGSize {
            self == .regular ? CGSize(width: 103, height: 66.4) : CGSize(width: 137, height: 46.6)
        }
        var fontSize: CGFloat { self == .regular ? 26.6 : 18.7 }
        var cornerRadius: CGFloat { self == .regular ? 15.9 : 11.2 }
        var spacing: CGFloat { self == .regular ? 20 : 9.2 }
    }

    let leftTitle: Text
    let rightTitle: Text
    @Binding var isRightSelected: Bool
    var size: Size = .regular

    var body: some View {
        HStack(spacing: size.spacing) {
            segment(leftTitle, isSelected: !isRightSelected) { isRightSelected = false }
            segment(rightTitle, isSelected: isRightSelected) { isRightSelected = true }
        }
    }

    private func segment(_ title: Text, isSelected: Bool, action: @escaping () -> Void) -> some View {
        ClickButton(action: action) {
            title
                .font(.atkinson(size: size.fontSize, weight: .bold))
                .textCase(.uppercase)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundStyle(isSelected ? Color.white : Color.toggleText)
                .padding(.horizontal, 8)
                .frame(width: size.buttonSize.width, height: size.buttonSize.height)
                .background {
                    RoundedRectangle(cornerRadius: size.cornerRadius)
                        .fill(
                            (isSelected ? Color.toggleSelected : Color.white)
                                .shadow(.inner(color: .black.opacity(0.25), radius: 1.3, y: 2))
                                .shadow(.inner(color: .black.opacity(0.25), radius: 1.3, y: -4.6))
                        )
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    SettingsView(onClose: {})
        .environment(AudioManager())
}
