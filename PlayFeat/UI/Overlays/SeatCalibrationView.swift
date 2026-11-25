//
//  SeatCalibrationView.swift
//  GetCooking
//
//  The screen between the main menu and the game: the player sits back far
//  enough that their upper body — shoulders down to hips — fits the frame.
//
//  The frame is the whole feedback loop. It shows faintly while the pose is
//  wrong; once it is right, the bright frame draws itself around the faint
//  one, and the game starts when it closes the loop.
//
//  Layout: Figma "calibration" (1950:936).
//

import AVFoundation
import Combine
import QuartzCore
import SwiftUI

struct SeatCalibrationView: View {
    var handPoseManager: HandPoseManager

    /// Called once the player has held the pose for the full dwell.
    var onCalibrated: () -> Void

    /// Set from the Settings sheet. In one-hand mode only the chosen hand has
    /// to be raised — the pose is otherwise impossible to hold  with one arm
    /// unavailable.
    @AppStorage(HandInputModeSetting.isOneHandKey) private var isOneHand = false
    @AppStorage(HandInputModeSetting.preferredHandKey) private var preferredHand: HandSide = .right

    private var inputMode: any HandInputMode {
        HandInputModeSetting.mode(isOneHand: isOneHand, preferredHand: preferredHand)
    }

    /// Same dwell detector the bin gesture uses, so "hold still for a moment"
    /// behaves identically across the game and the timing rules live in one
    /// place — including the stall cap that stops a hitch completing it.
    @State private var detector = HoverDetector()
    @State private var progress: CGFloat = 0

    /// The body publishes at camera rate, but a player sitting perfectly still
    /// stops publishing, so the dwell is driven by its own clock instead.
    private let tick = Timer.publish(every: 1 / 30, on: .main, in: .common).autoconnect()

    // MARK: - Layout

    /// The box the player fits into, in design points.
    private static let boxSize = CGSize(width: 1110, height: 565)
    /// The box sits low, so the camera sees the player from the waist up.
    private static let boxBottomMargin: CGFloat = 65
    private static let instructionTop: CGFloat = 187

    /// Smallest share of the box's width the player's shoulders may span.
    /// This is the "don't sit right at the back of the room" check.
    private static let minimumShoulderShare: CGFloat = 0.2

    private static let guideSize = CGSize(width: 698.57, height: 479)
    /// Gap between the guide's waist and the box's bottom edge.
    private static let guideBottomInset: CGFloat = 13

    private static let cornerRadius: CGFloat = 30.15
    /// Drawn inside the box's edge, so the box keeps its Figma outer size.
    private static let borderWidth: CGFloat = 15.07
    /// How strongly the frame shows before the player holds the pose.
    private static let waitingBorderOpacity = 0.35

    /// Where the player has to put themselves. Also handed to the pose
    /// pipeline: until calibration passes, nobody outside it is the player.
    static func targetFrame(in size: CGSize) -> CGRect {
        CGRect(
            x: (size.width - boxSize.width) / 2,
            y: size.height - boxSize.height - boxBottomMargin,
            width: boxSize.width,
            height: boxSize.height
        )
    }

    var body: some View {
        // The camera itself is mounted by ContentView and stays put across the
        // handover to the game; this screen only draws over it.
        ZStack {
            GeometryReader { proxy in
                let frame = Self.targetFrame(in: proxy.size)

                ZStack(alignment: .topLeading) {
                    instruction
                        .frame(width: proxy.size.width)
                        .offset(y: Self.instructionTop)

                    border
                        .frame(width: frame.width, height: frame.height)
                        .offset(x: frame.minX, y: frame.minY)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .onChange(of: proxy.size, initial: true) { _, size in
                    handPoseManager.setPlayerZone(Self.targetFrame(in: size), in: size)
                }
                .onReceive(tick) { _ in
                    // Recomputed here rather than captured from the body, so
                    // the dwell always reads the player's current position even
                    // in frames where nothing republished.
                    let aligned = isAligned(in: proxy.size, frame: frame)
                    let finished = detector.update(isHovering: aligned, now: CACurrentMediaTime())

                    progress = detector.progress
                    if finished { onCalibrated() }
                }
            }
            .allowsHitTesting(false)

            if handPoseManager.authorizationStatus == .denied
                || handPoseManager.authorizationStatus == .restricted
            {
                CameraPermissionDeniedOverlay()
            }
        }
        .onAppear { handPoseManager.start() }
    }

    private var instruction: some View {
        Text(instructionText)
            .font(.atkinson(size: 48, weight: .bold))
            .foregroundStyle(.neutralElevated)
            .outlined(.labelTab, width: 2)
            .multilineTextAlignment(.center)
    }

    /// The faint frame underneath, the bright one drawn over it as the dwell
    /// fills — so the progress reads as the frame lighting up, rather than as
    /// a separate gauge the player has to interpret.
    private var border: some View {
        let frameShape = RoundedRectangle(cornerRadius: Self.cornerRadius)
            .inset(by: Self.borderWidth / 2)
        return ZStack {
            guide

            frameShape
                .stroke(.calibrationFrame.opacity(Self.waitingBorderOpacity), lineWidth: Self.borderWidth)

            frameShape
                .trim(from: 0, to: progress)
                .stroke(.calibrationFrame, style: StrokeStyle(lineWidth: Self.borderWidth, lineCap: .round))
        }
    }

    /// The pose to copy: head and shoulders in the frame with both hands up.
    private var guide: some View {
        Image("CalibrationGuide")
            .resizable()
            .frame(width: Self.guideSize.width, height: Self.guideSize.height)
            .padding(.bottom, Self.guideBottomInset)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .accessibilityHidden(true)
    }

    /// Routed through `AppLocalization` rather than `Text` with a plain
    /// `String`: this is a computed `String`, and `Text(String)` renders its
    /// argument verbatim with no catalog lookup at all — which is how this
    /// stayed in English regardless of the language picker.
    private var instructionText: String {
        AppLocalization.string(inputMode.calibrationInstruction)
    }

    private func isAligned(in size: CGSize, frame: CGRect) -> Bool {
        guard let body = handPoseManager.playerBody(in: size) else { return false }
        return body.isAligned(
            in: frame,
            minimumShoulderSpan: frame.width * Self.minimumShoulderShare,
            mode: inputMode
        )
    }
}
