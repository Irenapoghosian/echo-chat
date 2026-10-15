import Combine
import UIKit

/// The chat list. Rows reorder with an animation when a new message arrives.
final class ConversationsViewController: UITableViewController {
    private typealias DataSource = UITableViewDiffableDataSource<Int, ConversationRow.ID>

    private let viewModel: ConversationsViewModel
    private let appearance: AppearanceStore
    private var rowsByID: [ConversationRow.ID: ConversationRow] = [:]
    private var cancellables = Set<AnyCancellable>()
    private lazy var dataSource = makeDataSource()

    init(viewModel: ConversationsViewModel, appearance: AppearanceStore) {
        self.viewModel = viewModel
        self.appearance = appearance
        super.init(style: .plain)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Chats"
        navigationItem.largeTitleDisplayMode = .always
        let settings = UIBarButtonItem(
            image: UIImage(systemName: "gearshape"),
            primaryAction: UIAction { [weak self] _ in self?.showSettings() }
        )
        settings.accessibilityLabel = "Settings"
        navigationItem.rightBarButtonItem = settings
        tableView.register(ConversationCell.self, forCellReuseIdentifier: ConversationCell.reuseID)
        tableView.dataSource = dataSource

        viewModel.$rows
            .sink { [weak self] rows in self?.render(rows) }
            .store(in: &cancellables)
    }

    private func makeDataSource() -> DataSource {
        DataSource(tableView: tableView) { [weak self] tableView, indexPath, id in
            guard
                let row = self?.rowsByID[id],
                let cell = tableView.dequeueReusableCell(withIdentifier: ConversationCell.reuseID, for: indexPath) as? ConversationCell
            else { return UITableViewCell() }
            cell.configure(with: row)
            return cell
        }
    }

    private func render(_ rows: [ConversationRow]) {
        let changed = rows.filter { rowsByID[$0.id] != nil && rowsByID[$0.id] != $0 }.map(\.id)
        rowsByID = Dictionary(uniqueKeysWithValues: rows.map { ($0.id, $0) })

        var snapshot = NSDiffableDataSourceSnapshot<Int, ConversationRow.ID>()
        snapshot.appendSections([0])
        snapshot.appendItems(rows.map(\.id))
        // Same row, new preview or time: redraw it in place.
        snapshot.reconfigureItems(changed)
        dataSource.apply(snapshot, animatingDifferences: view.window != nil)
    }

    private func showSettings() {
        let settings = UINavigationController(rootViewController: SettingsViewController(appearance: appearance))
        present(settings, animated: true)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard
            let id = dataSource.itemIdentifier(for: indexPath),
            let chatModel = viewModel.makeChatViewModel(for: id)
        else { return }
        navigationController?.pushViewController(ChatViewController(viewModel: chatModel), animated: true)
    }
}
