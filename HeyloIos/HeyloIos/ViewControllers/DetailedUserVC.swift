import UIKit
import SDWebImage

// MARK: - Badge Collection View Cell
class BadgeCollectionViewCell: UICollectionViewCell {

    private let emojiLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 30)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        backgroundColor = UIColor.darkGray.withAlphaComponent(0.5)
        layer.cornerRadius = 10

        contentView.addSubview(emojiLabel)
        contentView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            emojiLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -10),

            titleLabel.topAnchor.constraint(equalTo: emojiLabel.bottomAnchor, constant: 5),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 5),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -5),
        ])
    }

    func configure(with badgeType: DetailedUserVC.BadgeType) {
        emojiLabel.text = badgeType.emoji
        titleLabel.text = badgeType.rawValue
        backgroundColor = badgeType.color.withAlphaComponent(0.3)
    }
}

class DetailedUserVC: UIViewController {

    // MARK: - Properties
    private let user: NearbyUser

    // Badge types
    enum BadgeType: String, CaseIterable {
        case thanks = "Thanks"
        case myBad = "My Bad"
        case fashionCompliment = "Fashion"
        case professional = "Professional"
        case shaka = "Shaka"

        var emoji: String {
            switch self {
            case .thanks: return "🙏"
            case .myBad: return "😅"
            case .fashionCompliment: return "👗"
            case .professional: return "💼"
            case .shaka: return "🤙"
            }
        }

        var color: UIColor {
            switch self {
            case .thanks: return .systemBlue
            case .myBad: return .systemOrange
            case .fashionCompliment: return .systemPink
            case .professional: return .systemIndigo
            case .shaka: return .systemGreen
            }
        }
    }

    // Badge delay options
    private enum BadgeDelay: Int {
        case none = 0
        case fifteenMinutes = 15
        case thirtyMinutes = 30
        case sixtyMinutes = 60
    }

    // MARK: - UI Elements
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .black
        return scrollView
    }()

    private let contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }()

    // Header Section
    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .darkGray
        imageView.layer.cornerRadius = 16
        return imageView
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        label.textAlignment = .center
        return label
    }()

    private let moodContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.darkGray.withAlphaComponent(0.3)
        view.layer.cornerRadius = 12
        return view
    }()

    private let moodIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        return imageView
    }()

    private let moodTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Mood"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        return label
    }()

    private let moodLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 16)
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()

    private let lastActiveLabel: UILabel = {
        let label = UILabel()
        label.textColor = .lightGray
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .center
        return label
    }()

    // Info Section
    private let infoSectionView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.darkGray.withAlphaComponent(0.3)
        view.layer.cornerRadius = 12
        return view
    }()

    private let bioTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "About"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        return label
    }()

    private let bioLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 0
        return label
    }()

    private let distanceLabel: UILabel = {
        let label = UILabel()
        label.textColor = .lightGray
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()

    private let approachContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.darkGray.withAlphaComponent(0.3)
        view.layer.cornerRadius = 12
        return view
    }()

    private let approachTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "How to Approach"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        return label
    }()

    private let approachLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 0
        return label
    }()

    // Social Links Section
    private let socialLinksStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.alignment = .center
        stackView.spacing = 20
        return stackView
    }()

    // Action Buttons
    private let buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 15
        return stackView
    }()

    private lazy var shakaButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Shaka 🤙", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        button.tintColor = .white
        button.backgroundColor = UIColor.systemBlue
        button.layer.cornerRadius = 25
        button.addTarget(self, action: #selector(shakaButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var messageButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Message", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        button.tintColor = .white
        button.backgroundColor = UIColor.systemGreen
        button.layer.cornerRadius = 25
        button.addTarget(self, action: #selector(messageButtonTapped), for: .touchUpInside)
        return button
    }()

    // Badge Section (Item 4)
    private let badgesSectionView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.darkGray.withAlphaComponent(0.3)
        view.layer.cornerRadius = 12
        return view
    }()

    private let badgesTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Send a Badge"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        return label
    }()

    private let badgesCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        layout.itemSize = CGSize(width: 80, height: 100)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        return collectionView
    }()

    private let badgeHistoryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("View Badge History", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.tintColor = .white
        return button
    }()

    private let badgeDelayLabel: UILabel = {
        let label = UILabel()
        label.text = "Delay sending:"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()

    private let badgeDelaySegmentedControl: UISegmentedControl = {
        let items = ["None", "15m", "30m", "60m"]
        let segmentedControl = UISegmentedControl(items: items)
        segmentedControl.selectedSegmentIndex = 0
        return segmentedControl
    }()

    // Connection Index Section (Item 6)
    private let connectionIndexContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.darkGray.withAlphaComponent(0.3)
        view.layer.cornerRadius = 12
        return view
    }()

    private let connectionIndexTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Community Connection"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        return label
    }()

    private let connectionIndexLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 16)
        label.textAlignment = .left
        return label
    }()

    private let connectionIndexProgressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .bar)
        progressView.trackTintColor = UIColor.lightGray.withAlphaComponent(0.3)
        progressView.progressTintColor = .systemBlue
        progressView.layer.cornerRadius = 4
        progressView.clipsToBounds = true
        progressView.progress = 0.7 // Default value
        return progressView
    }()

    // Connection Readiness Framework (Item 3) - Placeholder
    private let connectionReadinessContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.darkGray.withAlphaComponent(0.3)
        view.layer.cornerRadius = 12
        view.isHidden = true // Hidden until implemented
        return view
    }()

    // Survey Framework (Item 5) - Placeholder
    private let surveyContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.darkGray.withAlphaComponent(0.3)
        view.layer.cornerRadius = 12
        view.isHidden = true // Hidden until implemented
        return view
    }()

    // Stats Section
    private let statsView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.darkGray.withAlphaComponent(0.3)
        view.layer.cornerRadius = 12
        return view
    }()

    private let statsTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Stats"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        return label
    }()

    private let shakasSentLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()

    private let shakasReceivedLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()

    // MARK: - Initialization
    init(user: NearbyUser) {
        self.user = user
        super.init(nibName: nil, bundle: nil)

        // Log user details for debugging
        print("DetailedUserVC initialized with user: \(user.displayName)")
        print("User ID: \(user.userId)")
        print("Profile Image URL: \(user.profileImageUrl)")
        print("Mood: \(user.moodTemperature)")
        print("Last Updated: \(user.lastUpdated)")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        configureUI()
    }

    // MARK: - Setup
    private func setupViews() {
        view.backgroundColor = .black
        title = user.displayName

        // Add back button
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )

        // Add report button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis"),
            style: .plain,
            target: self,
            action: #selector(moreOptionsButtonTapped)
        )

        // Add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        // Profile section
        contentView.addSubview(profileImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(lastActiveLabel)

        // Mood section
        contentView.addSubview(moodContainerView)
        moodContainerView.addSubview(moodTitleLabel)
        moodContainerView.addSubview(moodIconImageView)
        moodContainerView.addSubview(moodLabel)

        // Approach section
        contentView.addSubview(approachContainerView)
        approachContainerView.addSubview(approachTitleLabel)
        approachContainerView.addSubview(approachLabel)

        // Connection index section
        contentView.addSubview(connectionIndexContainerView)
        connectionIndexContainerView.addSubview(connectionIndexTitleLabel)
        connectionIndexContainerView.addSubview(connectionIndexLabel)
        connectionIndexContainerView.addSubview(connectionIndexProgressView)

        // Badge section
        contentView.addSubview(badgesSectionView)
        badgesSectionView.addSubview(badgesTitleLabel)
        badgesSectionView.addSubview(badgesCollectionView)
        badgesSectionView.addSubview(badgeDelayLabel)
        badgesSectionView.addSubview(badgeDelaySegmentedControl)
        badgesSectionView.addSubview(badgeHistoryButton)

        // Action buttons
        contentView.addSubview(shakaButton)
        contentView.addSubview(messageButton)

        // Stats section
        contentView.addSubview(statsView)
        statsView.addSubview(statsTitleLabel)
        statsView.addSubview(shakasSentLabel)
        statsView.addSubview(shakasReceivedLabel)

        // Placeholder sections (hidden)
        contentView.addSubview(connectionReadinessContainerView)
        contentView.addSubview(surveyContainerView)

        // Set up constraints
        setupConstraints()

        // Set up collection view
        badgesCollectionView.register(BadgeCollectionViewCell.self, forCellWithReuseIdentifier: "BadgeCell")
        badgesCollectionView.dataSource = self
        badgesCollectionView.delegate = self

        // Add actions to buttons
        badgeHistoryButton.addTarget(self, action: #selector(badgeHistoryButtonTapped), for: .touchUpInside)
        badgeDelaySegmentedControl.addTarget(self, action: #selector(badgeDelayChanged), for: .valueChanged)
    }

    private func setupConstraints() {
        // Make all views use auto layout
        let views: [UIView] = [
            scrollView, contentView, profileImageView, nameLabel, lastActiveLabel,
            moodContainerView, moodTitleLabel, moodIconImageView, moodLabel,
            approachContainerView, approachTitleLabel, approachLabel,
            connectionIndexContainerView, connectionIndexTitleLabel, connectionIndexLabel, connectionIndexProgressView,
            badgesSectionView, badgesTitleLabel, badgesCollectionView, badgeDelayLabel, badgeDelaySegmentedControl, badgeHistoryButton,
            statsView, statsTitleLabel, shakasSentLabel, shakasReceivedLabel,
            connectionReadinessContainerView, surveyContainerView
        ]

        for view in views {
            view.translatesAutoresizingMaskIntoConstraints = false
        }

        let padding: CGFloat = 16

        NSLayoutConstraint.activate([
            // Scroll View
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            // Content View
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // Profile Image View
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: padding),
            profileImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.6),
            profileImageView.heightAnchor.constraint(equalTo: profileImageView.widthAnchor),

            // Name Label
            nameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: padding),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),

            // Last Active Label
            lastActiveLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            lastActiveLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            lastActiveLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),

            // Mood Container View
            moodContainerView.topAnchor.constraint(equalTo: lastActiveLabel.bottomAnchor, constant: padding * 1.5),
            moodContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            moodContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),

            // Mood Title Label
            moodTitleLabel.topAnchor.constraint(equalTo: moodContainerView.topAnchor, constant: padding),
            moodTitleLabel.leadingAnchor.constraint(equalTo: moodContainerView.leadingAnchor, constant: padding),

            // Mood Icon Image View
            moodIconImageView.centerYAnchor.constraint(equalTo: moodTitleLabel.centerYAnchor),
            moodIconImageView.leadingAnchor.constraint(equalTo: moodTitleLabel.trailingAnchor, constant: 8),
            moodIconImageView.widthAnchor.constraint(equalToConstant: 24),
            moodIconImageView.heightAnchor.constraint(equalToConstant: 24),

            // Mood Label
            moodLabel.topAnchor.constraint(equalTo: moodTitleLabel.bottomAnchor, constant: 8),
            moodLabel.leadingAnchor.constraint(equalTo: moodContainerView.leadingAnchor, constant: padding),
            moodLabel.trailingAnchor.constraint(equalTo: moodContainerView.trailingAnchor, constant: -padding),
            moodLabel.bottomAnchor.constraint(equalTo: moodContainerView.bottomAnchor, constant: -padding),

            // Approach Container View
            approachContainerView.topAnchor.constraint(equalTo: moodContainerView.bottomAnchor, constant: padding),
            approachContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            approachContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),

            // Approach Title Label
            approachTitleLabel.topAnchor.constraint(equalTo: approachContainerView.topAnchor, constant: padding),
            approachTitleLabel.leadingAnchor.constraint(equalTo: approachContainerView.leadingAnchor, constant: padding),
            approachTitleLabel.trailingAnchor.constraint(equalTo: approachContainerView.trailingAnchor, constant: -padding),

            // Approach Label
            approachLabel.topAnchor.constraint(equalTo: approachTitleLabel.bottomAnchor, constant: 8),
            approachLabel.leadingAnchor.constraint(equalTo: approachContainerView.leadingAnchor, constant: padding),
            approachLabel.trailingAnchor.constraint(equalTo: approachContainerView.trailingAnchor, constant: -padding),
            approachLabel.bottomAnchor.constraint(equalTo: approachContainerView.bottomAnchor, constant: -padding),

            // Connection Index Container View
            connectionIndexContainerView.topAnchor.constraint(equalTo: approachContainerView.bottomAnchor, constant: padding),
            connectionIndexContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            connectionIndexContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),

            // Connection Index Title Label
            connectionIndexTitleLabel.topAnchor.constraint(equalTo: connectionIndexContainerView.topAnchor, constant: padding),
            connectionIndexTitleLabel.leadingAnchor.constraint(equalTo: connectionIndexContainerView.leadingAnchor, constant: padding),
            connectionIndexTitleLabel.trailingAnchor.constraint(equalTo: connectionIndexContainerView.trailingAnchor, constant: -padding),

            // Connection Index Label
            connectionIndexLabel.topAnchor.constraint(equalTo: connectionIndexTitleLabel.bottomAnchor, constant: 8),
            connectionIndexLabel.leadingAnchor.constraint(equalTo: connectionIndexContainerView.leadingAnchor, constant: padding),
            connectionIndexLabel.trailingAnchor.constraint(equalTo: connectionIndexContainerView.trailingAnchor, constant: -padding),

            // Connection Index Progress View
            connectionIndexProgressView.topAnchor.constraint(equalTo: connectionIndexLabel.bottomAnchor, constant: 8),
            connectionIndexProgressView.leadingAnchor.constraint(equalTo: connectionIndexContainerView.leadingAnchor, constant: padding),
            connectionIndexProgressView.trailingAnchor.constraint(equalTo: connectionIndexContainerView.trailingAnchor, constant: -padding),
            connectionIndexProgressView.heightAnchor.constraint(equalToConstant: 8),
            connectionIndexProgressView.bottomAnchor.constraint(equalTo: connectionIndexContainerView.bottomAnchor, constant: -padding),

            // Badges Section View
            badgesSectionView.topAnchor.constraint(equalTo: connectionIndexContainerView.bottomAnchor, constant: padding),
            badgesSectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            badgesSectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),

            // Badges Title Label
            badgesTitleLabel.topAnchor.constraint(equalTo: badgesSectionView.topAnchor, constant: padding),
            badgesTitleLabel.leadingAnchor.constraint(equalTo: badgesSectionView.leadingAnchor, constant: padding),
            badgesTitleLabel.trailingAnchor.constraint(equalTo: badgesSectionView.trailingAnchor, constant: -padding),

            // Badges Collection View
            badgesCollectionView.topAnchor.constraint(equalTo: badgesTitleLabel.bottomAnchor, constant: 8),
            badgesCollectionView.leadingAnchor.constraint(equalTo: badgesSectionView.leadingAnchor, constant: padding),
            badgesCollectionView.trailingAnchor.constraint(equalTo: badgesSectionView.trailingAnchor, constant: -padding),
            badgesCollectionView.heightAnchor.constraint(equalToConstant: 120),

            // Badge Delay Label
            badgeDelayLabel.topAnchor.constraint(equalTo: badgesCollectionView.bottomAnchor, constant: 8),
            badgeDelayLabel.leadingAnchor.constraint(equalTo: badgesSectionView.leadingAnchor, constant: padding),

            // Badge Delay Segmented Control
            badgeDelaySegmentedControl.centerYAnchor.constraint(equalTo: badgeDelayLabel.centerYAnchor),
            badgeDelaySegmentedControl.leadingAnchor.constraint(equalTo: badgeDelayLabel.trailingAnchor, constant: 8),
            badgeDelaySegmentedControl.trailingAnchor.constraint(equalTo: badgesSectionView.trailingAnchor, constant: -padding),

            // Badge History Button
            badgeHistoryButton.topAnchor.constraint(equalTo: badgeDelayLabel.bottomAnchor, constant: 8),
            badgeHistoryButton.trailingAnchor.constraint(equalTo: badgesSectionView.trailingAnchor, constant: -padding),
            badgeHistoryButton.bottomAnchor.constraint(equalTo: badgesSectionView.bottomAnchor, constant: -padding),

            // Stats View
            statsView.topAnchor.constraint(equalTo: badgesSectionView.bottomAnchor, constant: padding),
            statsView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            statsView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),

            // Stats Title Label
            statsTitleLabel.topAnchor.constraint(equalTo: statsView.topAnchor, constant: padding),
            statsTitleLabel.leadingAnchor.constraint(equalTo: statsView.leadingAnchor, constant: padding),
            statsTitleLabel.trailingAnchor.constraint(equalTo: statsView.trailingAnchor, constant: -padding),

            // Shakas Sent Label
            shakasSentLabel.topAnchor.constraint(equalTo: statsTitleLabel.bottomAnchor, constant: 8),
            shakasSentLabel.leadingAnchor.constraint(equalTo: statsView.leadingAnchor, constant: padding),
            shakasSentLabel.trailingAnchor.constraint(equalTo: statsView.trailingAnchor, constant: -padding),

            // Shakas Received Label
            shakasReceivedLabel.topAnchor.constraint(equalTo: shakasSentLabel.bottomAnchor, constant: 8),
            shakasReceivedLabel.leadingAnchor.constraint(equalTo: statsView.leadingAnchor, constant: padding),
            shakasReceivedLabel.trailingAnchor.constraint(equalTo: statsView.trailingAnchor, constant: -padding),
            shakasReceivedLabel.bottomAnchor.constraint(equalTo: statsView.bottomAnchor, constant: -padding),

            // Action Buttons
            shakaButton.topAnchor.constraint(equalTo: badgesSectionView.bottomAnchor, constant: padding * 1.5),
            shakaButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding * 2.5),
            shakaButton.trailingAnchor.constraint(equalTo: contentView.centerXAnchor, constant: -padding / 2),
            shakaButton.heightAnchor.constraint(equalToConstant: 50),

            messageButton.topAnchor.constraint(equalTo: badgesSectionView.bottomAnchor, constant: padding * 1.5),
            messageButton.leadingAnchor.constraint(equalTo: contentView.centerXAnchor, constant: padding / 2),
            messageButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding * 2.5),
            messageButton.heightAnchor.constraint(equalToConstant: 50),

            // Stats View
            statsView.topAnchor.constraint(equalTo: shakaButton.bottomAnchor, constant: padding * 1.5),

            // Make sure the content view extends to the bottom of the last element
            statsView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -padding)
        ])
    }

    private func configureUI() {
        // Basic user info
        nameLabel.text = user.displayName

        // Format last active time
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        let relativeDate = formatter.localizedString(for: user.lastUpdated, relativeTo: Date())
        lastActiveLabel.text = "Last active \(relativeDate)"

        // Configure mood section
        configureMoodSection()

        // Configure approach section
        configureApproachSection()

        // Configure connection index
        configureConnectionIndex()

        // Configure stats
        configureStats()

        // Load profile image
        if !user.profileImageUrl.isEmpty, let url = URL(string: user.profileImageUrl) {
            print("Loading profile image from URL: \(url)")
            profileImageView.sd_setImage(with: url, placeholderImage: UIImage(systemName: "person.circle.fill")) { [weak self] (image, error, cacheType, url) in
                if let error = error {
                    // If there's an error loading the image, use a placeholder and log the error
                    print("Error loading profile image: \(error.localizedDescription)")
                    self?.profileImageView.image = UIImage(systemName: "person.circle.fill")
                    self?.profileImageView.tintColor = .white
                } else if image != nil {
                    print("Successfully loaded profile image")
                }
            }
        } else {
            print("No profile image URL available, using placeholder")
            profileImageView.image = UIImage(systemName: "person.circle.fill")
            profileImageView.tintColor = .white
        }
    }

    private func configureMoodSection() {
        // Set mood icon based on temperature
        let moodEmoji = getMoodEmoji(for: user.moodTemperature)
        moodIconImageView.image = UIImage(systemName: getMoodIconName(for: user.moodTemperature))

        // Set mood text
        moodLabel.text = "\(moodEmoji) \(user.moodTemperature.capitalized)\n\nThis user is feeling \(user.moodTemperature.lowercased()) right now."
    }

    private func configureApproachSection() {
        // In a real app, this would come from the user's profile
        approachLabel.text = "I'm open to conversations about technology and startups. Feel free to say hi if you see me around campus!"
    }

    private func configureConnectionIndex() {
        // In a real app, this would be calculated based on user activity
        let connectionScore = 0.7 // 70%
        connectionIndexProgressView.progress = Float(connectionScore)

        let connectionLevel = getConnectionLevel(for: connectionScore)
        connectionIndexLabel.text = "\(connectionLevel) (\(Int(connectionScore * 100))%)\n\nThis user is actively connected with their community."
    }

    private func configureStats() {
        // In a real app, these would come from the user's profile
        shakasSentLabel.text = "Badges Sent: 12"
        shakasReceivedLabel.text = "Badges Received: 8"
    }

    // MARK: - Actions
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func shakaButtonTapped() {
        // Toggle shaka state
        if !user.hasLiked {
            // Update UI
            shakaButton.setTitle("Shaka'd 🤙", for: .normal)
            shakaButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.7)

            // Show success animation
            UIView.animate(withDuration: 0.2, animations: {
                self.shakaButton.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            }) { _ in
                UIView.animate(withDuration: 0.2) {
                    self.shakaButton.transform = .identity
                }
            }

            // TODO: Update in database
        }
    }

    @objc private func messageButtonTapped() {
        // TODO: Implement messaging functionality
        let alert = UIAlertController(title: "Coming Soon", message: "Messaging functionality will be available in a future update.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @objc private func moreOptionsButtonTapped() {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        actionSheet.addAction(UIAlertAction(title: "Report User", style: .destructive) { [weak self] _ in
            self?.reportUser()
        })

        actionSheet.addAction(UIAlertAction(title: "Block User", style: .destructive) { [weak self] _ in
            self?.blockUser()
        })

        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(actionSheet, animated: true)
    }

    @objc private func badgeHistoryButtonTapped() {
        let alert = UIAlertController(title: "Badge History", message: "You've exchanged badges with this user 3 times.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @objc private func badgeDelayChanged(_ sender: UISegmentedControl) {
        let delayOptions = ["No delay", "15 minutes", "30 minutes", "60 minutes"]
        let selectedDelay = delayOptions[sender.selectedSegmentIndex]

        let alert = UIAlertController(title: "Delay Set", message: "Badges will be sent with a \(selectedDelay) delay.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func sendBadge(_ badgeType: BadgeType) {
        // Get the selected delay
        let delayMinutes: Int
        switch badgeDelaySegmentedControl.selectedSegmentIndex {
        case 1: delayMinutes = 15
        case 2: delayMinutes = 30
        case 3: delayMinutes = 60
        default: delayMinutes = 0
        }

        let delayText = delayMinutes > 0 ? "in \(delayMinutes) minutes" : "now"

        let alert = UIAlertController(
            title: "Send \(badgeType.rawValue) Badge?",
            message: "This badge will be sent to the user \(delayText).",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Send", style: .default) { [weak self] _ in
            self?.confirmBadgeSent(badgeType, delayMinutes: delayMinutes)
        })

        present(alert, animated: true)
    }

    private func confirmBadgeSent(_ badgeType: BadgeType, delayMinutes: Int) {
        // In a real app, this would call the backend to send the badge

        let delayText = delayMinutes > 0 ? "in \(delayMinutes) minutes" : "now"

        let alert = UIAlertController(
            title: "Badge Sent!",
            message: "Your \(badgeType.rawValue) badge will be delivered \(delayText).",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func reportUser() {
        let alert = UIAlertController(title: "Report User", message: "Please select a reason for reporting this user:", preferredStyle: .alert)

        let reasons = ["Inappropriate content", "Harassment", "Spam", "Fake profile", "Other"]

        for reason in reasons {
            alert.addAction(UIAlertAction(title: reason, style: .default) { [weak self] _ in
                self?.submitReport(reason: reason)
            })
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(alert, animated: true)
    }

    private func submitReport(reason: String) {
        // TODO: Implement report submission to backend

        let alert = UIAlertController(title: "Report Submitted", message: "Thank you for helping keep Heylo safe. We'll review your report as soon as possible.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func blockUser() {
        let alert = UIAlertController(title: "Block User", message: "Are you sure you want to block this user? They will no longer be able to see you or interact with you.", preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Block", style: .destructive) { [weak self] _ in
            // TODO: Implement block functionality

            let confirmAlert = UIAlertController(title: "User Blocked", message: "This user has been blocked.", preferredStyle: .alert)
            confirmAlert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            })
            self?.present(confirmAlert, animated: true)
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(alert, animated: true)
    }

    // MARK: - Helper Methods

    private func getMoodEmoji(for mood: String) -> String {
        switch mood.lowercased() {
        case "cold":
            return "❄️"
        case "cool":
            return "😎"
        case "neutral":
            return "😐"
        case "warm":
            return "🙂"
        case "hot":
            return "🔥"
        default:
            return "😐"
        }
    }

    private func getMoodIconName(for mood: String) -> String {
        switch mood.lowercased() {
        case "cold":
            return "thermometer.snowflake"
        case "cool":
            return "thermometer.low"
        case "neutral":
            return "thermometer.medium"
        case "warm":
            return "thermometer.high"
        case "hot":
            return "thermometer.sun.fill"
        default:
            return "thermometer.medium"
        }
    }

    private func getConnectionLevel(for score: Double) -> String {
        switch score {
        case 0.0..<0.2:
            return "New to the area"
        case 0.2..<0.4:
            return "Occasional visitor"
        case 0.4..<0.6:
            return "Regular community member"
        case 0.6..<0.8:
            return "Active community member"
        case 0.8...1.0:
            return "Community pillar"
        default:
            return "Unknown"
        }
    }
}

// MARK: - UICollectionViewDataSource
extension DetailedUserVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return BadgeType.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BadgeCell", for: indexPath) as? BadgeCollectionViewCell else {
            return UICollectionViewCell()
        }

        let badgeType = BadgeType.allCases[indexPath.item]
        cell.configure(with: badgeType)

        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension DetailedUserVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let badgeType = BadgeType.allCases[indexPath.item]
        sendBadge(badgeType)
    }
}
