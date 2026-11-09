import ContentKit
import InjectionKit
import NotebookModuleInterface
import SwiftUI
import UserDataKit
import WordKit

/// Kelime Defterim ekranını kurar.
@MainActor
public final class NotebookCoordinator: NotebookModuleInterface {
  @Inject private var content: any ContentProviding
  @Inject private var userData: any UserDataStoring
  @Inject private var pronouncer: any Pronouncing

  public init() {}

  public func createNotebookView() -> AnyView {
    let viewModel = NotebookViewModel(content: content, userData: userData, pronouncer: pronouncer)
    return AnyView(NotebookView(viewModel: viewModel))
  }
}
