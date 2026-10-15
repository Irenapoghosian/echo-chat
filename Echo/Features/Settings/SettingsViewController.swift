import UIKit

/// Appearance (System, Light, Dark) and the app version, in an inset-grouped list.
final class SettingsViewController: UITableViewController {
    private enum Section: Int, CaseIterable {
        case appearance
        case about
    }

    private let appearance: AppearanceStore
    private let version: String

    init(appearance: AppearanceStore, bundle: Bundle = .main) {
        self.appearance = appearance
        let short = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        self.version = "\(short) (\(build))"
        super.init(style: .insetGrouped)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            systemItem: .done,
            primaryAction: UIAction { [weak self] _ in self?.dismiss(animated: true) }
        )
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Section(rawValue: section) == .appearance ? Appearance.allCases.count : 1
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        Section(rawValue: section) == .appearance ? "Appearance" : "About"
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        Section(rawValue: section) == .appearance ? "System follows the setting on your iPhone." : nil
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var content = UIListContentConfiguration.valueCell()
        if Section(rawValue: indexPath.section) == .appearance {
            let option = Appearance.allCases[indexPath.row]
            content.text = option.title
            cell.accessoryType = option == appearance.current ? .checkmark : .none
            cell.selectionStyle = .default
            cell.accessibilityTraits = option == appearance.current ? [.button, .selected] : .button
        } else {
            content.text = "Version"
            content.secondaryText = version
            cell.accessoryType = .none
            cell.selectionStyle = .none
            cell.accessibilityTraits = .staticText
        }
        cell.contentConfiguration = content
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard Section(rawValue: indexPath.section) == .appearance else { return }
        appearance.select(Appearance.allCases[indexPath.row])
        tableView.reloadSections(IndexSet(integer: Section.appearance.rawValue), with: .none)
    }
}
