import Combine
import PhotosUI
import UIKit

/// One conversation: messages grouped by day, the composer riding on the keyboard,
/// "typing…" in the title, and photos that open full screen.
final class ChatViewController: UIViewController {
    private typealias DataSource = UITableViewDiffableDataSource<Date, Message.ID>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Date, Message.ID>

    private let viewModel: ChatViewModel
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let titleView = ChatTitleView()
    private lazy var inputBar: ChatInputBar = {
        let bar = ChatInputBar(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 52))
        bar.delegate = self
        return bar
    }()
    private lazy var dataSource = makeDataSource()
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: ChatViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // The composer is the input accessory view, so it stays on screen with or without the keyboard.
    override var inputAccessoryView: UIView? { inputBar }
    override var canBecomeFirstResponder: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.titleView = titleView
        configureTable()
        bind()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
    }

    // MARK: - Setup

    private func configureTable() {
        tableView.register(MessageCell.self, forCellReuseIdentifier: MessageCell.reuseID)
        tableView.register(DayHeaderView.self, forHeaderFooterViewReuseIdentifier: DayHeaderView.reuseID)
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        tableView.keyboardDismissMode = .interactive
        tableView.sectionHeaderTopPadding = 0
        tableView.delegate = self
        tableView.dataSource = dataSource
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    private func bind() {
        viewModel.$sections
            .sink { [weak self] sections in self?.render(sections) }
            .store(in: &cancellables)

        viewModel.$isContactTyping
            .sink { [weak self] isTyping in
                guard let self else { return }
                titleView.configure(name: viewModel.contact.name, isTyping: isTyping)
            }
            .store(in: &cancellables)

        // The keyboard frame includes the composer, so this keeps the last message visible either way.
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
            .sink { [weak self] notification in self?.keyboardWillChangeFrame(notification) }
            .store(in: &cancellables)
    }

    private func makeDataSource() -> DataSource {
        DataSource(tableView: tableView) { [weak self] tableView, indexPath, id in
            guard
                let self,
                let message = viewModel.message(with: id),
                let cell = tableView.dequeueReusableCell(withIdentifier: MessageCell.reuseID, for: indexPath) as? MessageCell
            else { return UITableViewCell() }
            cell.configure(with: message, contactName: viewModel.contact.name) { [weak self] image in
                self?.showPhoto(image)
            }
            return cell
        }
    }

    // MARK: - Updates

    private func render(_ sections: [MessageSection]) {
        var snapshot = Snapshot()
        for section in sections {
            snapshot.appendSections([section.day])
            snapshot.appendItems(section.messages.map(\.id), toSection: section.day)
        }
        let isFirstLoad = dataSource.snapshot().numberOfItems == 0
        dataSource.apply(snapshot, animatingDifferences: !isFirstLoad) { [weak self] in
            self?.scrollToBottom(animated: !isFirstLoad)
        }
    }

    private func scrollToBottom(animated: Bool) {
        guard
            let last = dataSource.snapshot().itemIdentifiers.last,
            let indexPath = dataSource.indexPath(for: last)
        else { return }
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
    }

    private func keyboardWillChangeFrame(_ notification: Notification) {
        guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let keyboard = view.convert(frame, from: nil)
        let overlap = max(0, view.bounds.maxY - keyboard.minY - view.safeAreaInsets.bottom)
        tableView.contentInset.bottom = overlap
        tableView.verticalScrollIndicatorInsets.bottom = overlap
        scrollToBottom(animated: false)
    }

    private func showPhoto(_ image: UIImage) {
        present(ImageViewerController(image: image), animated: true)
    }
}

// MARK: - Day headers

extension ChatViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard
            let day = dataSource.sectionIdentifier(for: section),
            let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: DayHeaderView.reuseID) as? DayHeaderView
        else { return nil }
        header.configure(title: viewModel.title(forSectionOn: day) ?? "")
        return header
    }
}

// MARK: - Sending

extension ChatViewController: ChatInputBarDelegate {
    func inputBar(_ inputBar: ChatInputBar, didSend text: String) {
        viewModel.send(text: text)
    }

    func inputBarDidTapPhoto(_ inputBar: ChatInputBar) {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }
}

extension ChatViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let image = object as? UIImage else { return }
            Task { @MainActor in
                self?.viewModel.send(image: image)
            }
        }
    }
}
