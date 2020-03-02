import Cocoa

struct GuaranteeSection {
    var title: String
    var explaination: String
    var buttonText: String?
    var buttonAction: (() -> Void)?
}

protocol GuaranteeViewControllerDelegate: AnyObject {
    func viewDidExpand(controller: GuaranteeViewController)
}

class GuaranteeViewController: NSViewController {
    let advancedButtonTopPadding: CGFloat = 5

    var plusLabel: NSTextField!
    var titleLabel: NSTextField!
    var explainationLabel: NSTextField!
    var dividorBox: NSBox!
    var dividorTopConstraint: NSLayoutConstraint!
    var revealButton: HoverButton!
    var advancedButton: HoverButton?
    var advancedAction: (() -> Void)?
    var expanded: Bool = false
    weak var delegate: GuaranteeViewControllerDelegate?

    private lazy var contentView = NSView()

    override func loadView() {
       view = contentView
    }

    init(guarantee: GuaranteeSection) {
        super.init(nibName: nil, bundle: nil)
        
        revealButton = HoverButton()
        revealButton.title = ""
        revealButton.translatesAutoresizingMaskIntoConstraints = false
        revealButton.isBordered = false
        revealButton.target = self
        revealButton.action = #selector(revealButtonClicked(_:))
        self.view.addSubview(revealButton)
        
        NSLayoutConstraint.activate([
            revealButton.topAnchor.constraint(equalTo: self.view.topAnchor),
            revealButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            revealButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
        ])
        
        plusLabel = NSTextField.makeLabel(text: "+", size: 26, weight: .regular)
        titleLabel = NSTextField.makeLabel(text: guarantee.title, size: 18, weight: .regular)
        revealButton.addSubview(plusLabel)
        revealButton.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            plusLabel.leadingAnchor.constraint(equalTo: revealButton.leadingAnchor, constant: 10),
            plusLabel.topAnchor.constraint(equalTo: revealButton.topAnchor, constant: 9),
            titleLabel.topAnchor.constraint(equalTo: revealButton.topAnchor, constant: 16),
            titleLabel.widthAnchor.constraint(equalToConstant: 394),
            titleLabel.leadingAnchor.constraint(equalTo: plusLabel.trailingAnchor, constant: 8),
            revealButton.bottomAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8)
        ])
        
        explainationLabel = NSTextField.makeLabel(text: guarantee.explaination, size: 17, weight: .regular, color: .secondaryLabelColor)
        explainationLabel.wantsLayer = true

        let textParagraph = NSMutableParagraphStyle()
        textParagraph.lineSpacing = AppManager.shared.isLanguageZhFamily ? 5 : 3
        let attribs = [NSAttributedString.Key.font: NSFont.systemFont(ofSize: AppManager.shared.isLanguageZhFamily ? 16 : 16.5),
                       NSAttributedString.Key.foregroundColor: NSColor.secondaryLabelColor,
                       NSAttributedString.Key.paragraphStyle: textParagraph]
        let attrString = NSAttributedString.init(string: guarantee.explaination, attributes: attribs)
        explainationLabel.attributedStringValue = attrString

        self.view.addSubview(explainationLabel)
        NSLayoutConstraint.activate([
            explainationLabel.topAnchor.constraint(equalTo: revealButton.bottomAnchor, constant: 8),
            explainationLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 34),
            explainationLabel.widthAnchor.constraint(equalToConstant: 397),
        ])
        
        if let buttonText = guarantee.buttonText {
            advancedAction = guarantee.buttonAction
            advancedButton = HoverButton()
            if #available(OSX 10.14, *) {
                advancedButton?.contentTintColor = .controlAccentColor
            }
            advancedButton?.alignment = .left
            advancedButton?.title = buttonText
            advancedButton?.updateTitle(titleSize: AppManager.shared.isLanguageZhFamily ? 16: 17, chevronSize: 22, chevronOffset: 1.2)
            advancedButton?.translatesAutoresizingMaskIntoConstraints = false
            advancedButton?.isBordered = false
            advancedButton?.target = self
            advancedButton?.action = #selector(advancedButtonClicked(_:))
            self.view.safelyAddSubview(advancedButton)
        }
        
        dividorBox = NSBox()
        dividorBox.boxType = .separator
        dividorBox.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(dividorBox)
        
        if let advancedButton = advancedButton {
            NSLayoutConstraint.activate([
                advancedButton.topAnchor.constraint(equalTo: explainationLabel.bottomAnchor, constant: advancedButtonTopPadding),
                advancedButton.leadingAnchor.constraint(equalTo: explainationLabel.leadingAnchor, constant: -2.5),
                advancedButton.widthAnchor.constraint(equalTo: explainationLabel.widthAnchor)
            ])
            dividorTopConstraint = dividorBox.topAnchor.constraint(equalTo: advancedButton.bottomAnchor)
        } else {
            dividorTopConstraint = dividorBox.topAnchor.constraint(equalTo: explainationLabel.bottomAnchor)
        }

        NSLayoutConstraint.activate([
            dividorTopConstraint,
            dividorBox.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            dividorBox.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: 7),
            dividorBox.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
        
        self.view.layoutSubtreeIfNeeded()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }

    @objc func advancedButtonClicked(_ sender: Any) {
        advancedAction?()
    }
    
    @objc func revealButtonClicked(_ sender: Any) {
        if (!expanded) {
            runAnimationGroup(parameter: self.expand, duration: 0.3)
        }
    }
    
    func expand() {
        self.explainationLabel.alphaValue = 1
        dividorTopConstraint.constant = 12
        delegate?.viewDidExpand(controller: self)
        expanded = true
    }
    
    func collapse() {
        self.explainationLabel.alphaValue = 0
        dividorTopConstraint.constant = -explainationLabel.bounds.size.height
        if let advancedButton = advancedButton {
            dividorTopConstraint.constant -= (advancedButton.bounds.size.height + advancedButtonTopPadding)
        }
        expanded = false
    }
}
