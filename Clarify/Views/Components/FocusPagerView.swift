//
//  FocusPagerView.swift
//  Clarify
//
//  A deliberately restrictive paging container: exactly one step is ever
//  on screen, and the only way forward is the giant "Next Step" button.
//  This is a custom layout rather than a free-swiping `.tabViewStyle(.page)`
//  on purpose — a draggable page view makes it easy for a thumb to flick
//  past a step the WorkflowManager hasn't actually unlocked yet. Driving
//  transitions entirely from `manager.currentStepIndex` keeps the two
//  perfectly in sync.
//

import SwiftUI

struct FocusPagerView<StepContent: View>: View {
    let manager: WorkflowManager
    var onFinished: () -> Void
    @ViewBuilder var content: (WorkflowStep) -> StepContent

    @Environment(GamificationManager.self) private var gamification
    @State private var showResetConfirmation = false
    @State private var didResetGuide = false

    /// Only offered once there's actually something to lose — a guide
    /// still on its first, untouched step has nothing to reset.
    private var hasProgressToReset: Bool {
        !manager.isFirstStep || !manager.completedStepIDs.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 20)
                .padding(.top, 12)

            ScrollView {
                content(manager.currentStep)
                    .id(manager.currentStep.id)
                    .padding(20)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        )
                    )
            }
            .animation(.spring(response: 0.42, dampingFraction: 0.86), value: manager.currentStepIndex)

            controls
                .padding(20)
                .background(.bar)
        }
        .navigationTitle(manager.workflow.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if hasProgressToReset {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showResetConfirmation = true
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                    }
                    .accessibilityLabel("Reset this guide")
                }
            }
        }
        .confirmationDialog(
            "Reset this guide?",
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset to Step 1", role: .destructive) {
                manager.resetProgress()
                didResetGuide.toggle()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your progress on \"\(manager.workflow.title)\" will go back to the first step. XP you've already earned stays put.")
        }
        .sensoryFeedback(.warning, trigger: didResetGuide)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Step \(manager.currentStepIndex + 1) of \(manager.workflow.steps.count)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            ProgressView(value: manager.progressFraction)
                .tint(.accentColor)
                .accessibilityLabel("Workflow progress")
                .accessibilityValue("Step \(manager.currentStepIndex + 1) of \(manager.workflow.steps.count)")
        }
    }

    private var controls: some View {
        AdaptiveHStack {
            if !manager.isFirstStep {
                Button {
                    manager.retreat()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3.weight(.semibold))
                        .frame(width: 60, height: 60)
                }
                .buttonStyle(.bordered)
                .clipShape(Circle())
                .accessibilityLabel("Previous step")
            }

            Button {
                let wasLastStep = manager.isLastStep
                let completedStep = manager.currentStep
                manager.advance()
                gamification.awardStepCompletion(stepID: completedStep.id, xpValue: completedStep.xpValue)
                if wasLastStep {
                    gamification.recordWorkflowCompleted(manager.workflow)
                    onFinished()
                }
            } label: {
                Text(manager.isLastStep ? "Finish" : "Next Step")
                    .font(.title3.weight(.semibold))
                    // HIG-minimum-plus touch target: 60pt tall, full width,
                    // reachable with a thumb from the bottom of the screen.
                    .frame(maxWidth: .infinity, minHeight: 60)
            }
            .buttonStyle(.borderedProminent)
            .sensoryFeedback(.success, trigger: manager.completionPulse)
        }
    }
}
