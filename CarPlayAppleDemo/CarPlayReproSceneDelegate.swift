#if os(iOS)
import CarPlay
import Combine
import UIKit

/// The phone screen and the CarPlay scene share this log so a successful tap is unambiguous.
final class CarPlayTapLog: ObservableObject {
    static let shared = CarPlayTapLog()

    @Published private(set) var continueTripCount = 0
    @Published private(set) var nextStopCount = 0
    @Published private(set) var lastAction = "No header action received"

    private init() {}

    func record(_ action: HeaderAction) -> Int {
        switch action {
        case .continueTrip:
            continueTripCount += 1
            lastAction = "Continue Trip received"
            print("CarPlay header action: Continue Trip (\(continueTripCount))")
            return continueTripCount
        case .nextStop:
            nextStopCount += 1
            lastAction = "Next Stop received"
            print("CarPlay header action: Next Stop (\(nextStopCount))")
            return nextStopCount
        }
    }
}

enum HeaderAction {
    case continueTrip
    case nextStop

    var title: String {
        switch self {
        case .continueTrip: "Continue Trip"
        case .nextStop: "Next Stop"
        }
    }

    var symbol: String {
        switch self {
        case .continueTrip: "calendar.badge.clock"
        case .nextStop: "location.fill"
        }
    }
}

/// Fixed sample data with the same native details-header and list construction as Sidetrip.
final class CarPlayReproSceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    private var interfaceController: CPInterfaceController?
    private let tapLog = CarPlayTapLog.shared

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = interfaceController
        interfaceController.setRootTemplate(tripsTemplate(), animated: false, completion: nil)
    }

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnectInterfaceController interfaceController: CPInterfaceController
    ) {
        self.interfaceController = nil
    }

    private func tripsTemplate() -> CPListTemplate {
        let card = cardElement(title: "Coastal Road Trip", subtitle: "Sep 23 – Sep 25", symbol: "suitcase.rolling")
        let row = CPListImageRowItem(text: nil, cardElements: [card], allowsMultipleLines: true)
        row.listImageRowHandler = { [weak self] _, _, completion in
            defer { completion() }
            self?.showTrip()
        }
        return CPListTemplate(title: "Trips", sections: [CPListSection(items: [row])])
    }

    private func showTrip() {
        let template = tripTemplate()
        interfaceController?.setRootTemplate(template, animated: true, completion: nil)
    }

    private func tripTemplate() -> CPListTemplate {
        let header = detailsHeader(
            title: "Coastal Road Trip", subtitle: "Sep 23 – Sep 25", symbol: "suitcase.rolling",
            status: nil,
            bodyVariants: [
                "0 of 2 days complete · Next: Day 1 · Coastal Walk · A short trip along the coast with two full days of sightseeing.",
                "0 of 2 days complete · Next: Day 1 · Coastal Walk",
                "0 of 2 days complete"
            ],
            action: .continueTrip
        )
        // Sidetrip presents the full header initially, then updates the card sections.
        let template = CPListTemplate(title: "Coastal Road Trip", listHeader: header,
                                      sections: [], assistantCellConfiguration: nil)
        let back = UIImage(systemName: "chevron.backward") ?? UIImage()
        template.leadingNavigationBarButtons = [CPBarButton(image: back) { [weak self] _ in
            guard let self, let interfaceController = self.interfaceController else { return }
            interfaceController.setRootTemplate(self.tripsTemplate(), animated: true, completion: nil)
        }]

        let cards = [
            cardElement(title: "Day 1 · Coastal Walk", subtitle: "Sep 23", symbol: "calendar", status: "Not Started"),
            cardElement(title: "Day 2 · Old Town", subtitle: "Sep 24", symbol: "calendar", status: "Not Started")
        ]
        let row = CPListImageRowItem(text: nil, cardElements: cards, allowsMultipleLines: true)
        row.listImageRowHandler = { [weak self] _, index, completion in
            defer { completion() }
            self?.showDay(index: index)
        }
        template.updateSections([CPListSection(items: [row], header: "Part 1: Coast", sectionIndexTitle: nil)])
        return template
    }

    private func showDay(index: Int) {
        guard (0...1).contains(index) else { return }
        interfaceController?.pushTemplate(dayTemplate(index: index), animated: true, completion: nil)
    }

    private func dayTemplate(index: Int) -> CPListTemplate {
        let day = index + 1
        let title = day == 1 ? "Coastal Walk" : "Old Town"
        let next = day == 1 ? "Lighthouse" : "Town Square"
        let header = detailsHeader(
            title: "Day \(day) · \(title)", subtitle: day == 1 ? "Sep 23" : "Sep 24",
            symbol: "calendar", status: "Not Started",
            bodyVariants: [
                "3 of 3 stops remaining · Next: \(next) · Visit three places and enjoy the scenery along the way.",
                "3 of 3 stops remaining · Next: \(next)",
                "3 of 3 stops remaining"
            ],
            action: .nextStop
        )
        let stops = [next, "Scenic Viewpoint", "Lunch Stop"].enumerated().map { index, name in
            let item = CPListItem(text: name, detailText: "\(9 + index):00 - 1h",
                                  image: UIImage(systemName: "circle"))
            item.handler = { [weak self] _, completion in
                defer { completion() }
                self?.showAlert("Stop row selected: \(name)")
            }
            return item
        }
        return CPListTemplate(title: "Day \(day)", listHeader: header,
                              sections: [CPListSection(items: stops)], assistantCellConfiguration: nil)
    }

    private func detailsHeader(
        title: String, subtitle: String, symbol: String, status: String?,
        bodyVariants: [String], action: HeaderAction
    ) -> CPListTemplateDetailsHeader {
        let thumbnail = thumbnail(symbol: symbol, status: status)
        var buttons: [CPButton] = []
        if CPListTemplateDetailsHeader.maximumActionButtonCount > 0 {
            let image = UIImage(systemName: action.symbol) ?? UIImage()
            let button = CPButton(image: image) { [weak self] _ in
                guard let self else { return }
                let count = self.tapLog.record(action)
                self.showAlert("\(action.title) handler called (\(count))")
            }
            button.title = action.title
            button.isEnabled = true
            buttons = [button]
        }
        let header = CPListTemplateDetailsHeader(
            thumbnail: thumbnail, title: title, subtitle: subtitle,
            bodyVariants: bodyVariants.map { NSAttributedString(string: $0) }, actionButtons: buttons
        )
        header.wantsAdaptiveBackgroundStyle = true
        return header
    }

    private func cardElement(title: String, subtitle: String, symbol: String,
                             status: String? = nil) -> CPListImageRowItemCardElement {
        let card = CPListImageRowItemCardElement(
            thumbnail: thumbnail(symbol: symbol, status: status), title: title, subtitle: subtitle,
            tintColor: UIColor(white: 0.08, alpha: 1)
        )
        card.accessibilityLabel = [title, subtitle, status].compactMap { $0 }.joined(separator: ", ")
        return card
    }

    private func thumbnail(symbol: String, status: String?) -> CPThumbnailImage {
        let size = CPThumbnailImage.maximumImageSize(forAspectRatio: 16.0 / 9.0)
        let format = UIGraphicsImageRendererFormat()
        format.scale = max(1, interfaceController?.carTraitCollection.displayScale ?? 2)
        let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor(white: 0.22, alpha: 1).setFill()
            context.fill(CGRect(origin: .zero, size: size))
            let pointSize = min(size.width, size.height) * 0.3
            let icon = UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: pointSize))?
                .withTintColor(.white, renderingMode: .alwaysOriginal)
            if let icon {
                icon.draw(at: CGPoint(x: (size.width - icon.size.width) / 2,
                                      y: (size.height - icon.size.height) / 2))
            }
        }
        let result = CPThumbnailImage(image: image)
        if let status {
            result.imageOverlay = CPImageOverlay(text: status, textColor: .white,
                                                 backgroundColor: UIColor.black.withAlphaComponent(0.8),
                                                 alignment: .trailing)
        }
        return result
    }

    private func showAlert(_ title: String) {
        let ok = CPAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.interfaceController?.dismissTemplate(animated: true, completion: nil)
        }
        interfaceController?.presentTemplate(CPAlertTemplate(titleVariants: [title], actions: [ok]),
                                             animated: true, completion: nil)
    }
}
#endif
