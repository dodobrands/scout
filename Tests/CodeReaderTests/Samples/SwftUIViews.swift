import DFoundation
import DUIKit
import PreviewSnapshots
import SwiftUI

struct SelectFullDateView: View {
    @StateObject
    var viewModel: SelectDateViewController.ViewModel

    @Environment(\.presentationMode)
    var presentationMode

    @State
    var isAlertPresented = false

    var body: some View {
        VStack {
            Spacer()
            VStack(alignment: .center, spacing: 12) {
                HStack {
                    Button(
                        action: {
                            presentationMode.wrappedValue.dismiss()
                        },
                        label: {
                            Text(
                                "cancelNoun",
                                bundle: .module,
                                comment: "The 'Cancel' button title, noun"
                            )
                            .padding(12)
                        }
                    ).accessibilityIdentifier("cancelSetDate")
                    Spacer()
                    Button(
                        action: {
                            isAlertPresented = true
                        },
                        label: {
                            Text(
                                "done",
                                bundle: .module,
                                comment: "The 'Done' button title"
                            )
                            .padding(12)
                        }
                    ).accessibilityIdentifier("doneSetDate")
                }
                .foregroundColor(Color.TextAndIcons.accent)
                .fontStyle(LabelStyle.buttonM)
                switch viewModel.missingComponents {
                case .full:
                    DatePicker(
                        "",
                        selection: $viewModel.date,
                        in: ...viewModel.maxDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.wheel)
                    .clipped()
                    .labelsHidden()
                case .year:
                    Picker("", selection: $viewModel.year) {
                        ForEach(viewModel.minYear...viewModel.maxYear, id: \.self) { year in
                            Text(String(year))
                        }
                    }.pickerStyle(.wheel)
                }
            }
            .padding(.bottom, 10)
            .background(Color.Background.primary.ignoresSafeArea())
        }
        .background(Color.Background.overlay.ignoresSafeArea())
        .accessibilityAction(
            .escape,
            {
                presentationMode.wrappedValue.dismiss()
            }
        )
        .accessibilityAction(
            .magicTap,
            {
                isAlertPresented = true
            }
        )
        .alert(isPresented: $isAlertPresented) {
            Alert(
                title: Text("onceTheBirthdayDateIsSet", bundle: .module),
                message: Text(
                    String(
                        format: NSLocalizedString(
                            "setTheDateForWithParam",
                            bundle: .module,
                            comment: ""
                        ),
                        viewModel.formattedDate()
                    )
                ),
                primaryButton: .default(
                    Text(
                        "confirm",
                        bundle: .module
                    ),
                    action: {
                        viewModel.done()
                        presentationMode.wrappedValue.dismiss()
                    }
                ),
                secondaryButton: .cancel(
                    Text(
                        "cancelNoun",
                        bundle: .module,
                        comment: "The 'Cancel' button title, noun"
                    )
                )
            )
        }
    }
}

// MARK: - Preview

struct SelectFullDateView_Previews: PreviewProvider {
    static var previews: some View {
        snapshots.previews
    }

    static var snapshots: PreviewSnapshots<SelectDateViewController.ViewModel.SelectionState> {
        PreviewSnapshots(
            configurations: [
                PreviewSnapshots.Configuration(name: "Full", state: .full),
                PreviewSnapshots.Configuration(name: "Year", state: .year),
            ]) { state in
                SelectFullDateView(
                    viewModel: SelectDateViewController.ViewModel(
                        missingComponents: state,
                        today: Date(year: 2024, month: 05, day: 02)
                    )
                ).frame(width: 414, height: 414)
            }
    }
}
