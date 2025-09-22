import UIKit

final class MovieQuizViewController: UIViewController, QuestionFactoryDelegate {

    // MARK: - Outlets
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var textLabel: UILabel!
    @IBOutlet private var counterLabel: UILabel!
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!

    // MARK: - Properties
    private var currentQuestionIndex = 0
    private var correctAnswers = 0
    private let questionsAmount = 10
    private var currentQuestion: QuizQuestion?
    private var questionFactory: QuestionFactoryProtocol?
    private let alertPresenter = AlertPresenter()
    private var statisticService: StatisticServiceProtocol?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        print("✅ viewDidLoad called")

        setupUI()
        statisticService = StatisticService()

        questionFactory = QuestionFactory(moviesLoader: MoviesLoader(), delegate: self)
        print("✅ questionFactory initialized: \(questionFactory != nil)")

        showLoadingIndicator()
        questionFactory?.loadData()
    }

    // MARK: - UI Setup
    private func setupUI() {
        imageView.layer.cornerRadius = 20
    }

    // MARK: - QuestionFactoryDelegate
    func didReceiveNextQuestion(question: QuizQuestion?) {
        print("📥 didReceiveNextQuestion")

        guard let question = question else {
            showNetworkError(message: "Не удалось загрузить вопрос")
            return
        }

        currentQuestion = question
        let viewModel = convert(model: question)

        DispatchQueue.main.async { [weak self] in
            self?.hideLoadingIndicator()
            self?.show(quiz: viewModel)
        }
    }

    func didLoadDataFromServer() {
        print("✅ Data loaded from server")
        DispatchQueue.main.async { [weak self] in
            self?.activityIndicator.isHidden = true
            self?.questionFactory?.requestNextQuestion()
        }
    }

    func didFailToLoadData(with error: Error) {
        print("❌ Failed to load data: \(error.localizedDescription)")
        showNetworkError(message: error.localizedDescription)
    }

    // MARK: - Actions
    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        guard let currentQuestion = currentQuestion else { return }
        showAnswerResult(isCorrect: currentQuestion.correctAnswer)
    }

    @IBAction private func noButtonClicked(_ sender: UIButton) {
        guard let currentQuestion = currentQuestion else { return }
        showAnswerResult(isCorrect: !currentQuestion.correctAnswer)
    }

    // MARK: - Quiz Logic
    private func convert(model: QuizQuestion) -> QuizStepViewModel {
        QuizStepViewModel(
            image: UIImage(data: model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)"
        )
    }

    private func show(quiz step: QuizStepViewModel) {
        imageView.image = step.image
        textLabel.text = step.question
        counterLabel.text = step.questionNumber
        imageView.layer.borderWidth = 0
        imageView.layer.borderColor = nil
    }

    private func show(quiz result: QuizResultsViewModel) {
        statisticService?.store(correct: correctAnswers, total: questionsAmount)

        guard let bestGame = statisticService?.bestGame else { return }
        let bestGameDateFormatted = bestGame.date.dateTimeString
        let accuracy = String(format: "%.2f", statisticService?.totalAccuracy ?? 0)

        let message = """
        Ваш результат: \(correctAnswers)/\(questionsAmount)
        Кол-во квизов: \(statisticService?.gamesCount ?? 0)
        Рекорд: \(bestGame.correct)/\(bestGame.total) (\(bestGameDateFormatted))
        Средняя точность: \(accuracy)%
        """

        let alertModel = AlertModel(
            title: result.title,
            message: message,
            buttonText: result.buttonText
        ) { [weak self] in
            self?.restartGame()
        }

        alertPresenter.show(in: self, model: alertModel)
    }

    private func restartGame() {
        currentQuestionIndex = 0
        correctAnswers = 0
        showLoadingIndicator()
        questionFactory?.requestNextQuestion()
    }

    private func showAnswerResult(isCorrect: Bool) {
        if isCorrect { correctAnswers += 1 }

        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 8
        imageView.layer.borderColor = (isCorrect ? UIColor.ypGreen : UIColor.ypRed).cgColor

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.showNextQuestionOrResults()
        }
    }

    private func showNextQuestionOrResults() {
        if currentQuestionIndex == questionsAmount - 1 {
            let resultModel = QuizResultsViewModel(
                title: "Раунд окончен!",
                text: correctAnswers == questionsAmount
                    ? "Поздравляем, вы ответили на все вопросы!"
                    : "Вы ответили на \(correctAnswers) из 10. Попробуйте ещё раз!",
                buttonText: "Сыграть ещё раз"
            )
            show(quiz: resultModel)
        } else {
            currentQuestionIndex += 1
            showLoadingIndicator()
            questionFactory?.requestNextQuestion()
        }
    }

    // MARK: - Loading Indicator
    private func showLoadingIndicator() {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
    }

    private func hideLoadingIndicator() {
        activityIndicator.isHidden = true
        activityIndicator.stopAnimating()
    }

    // MARK: - Network Error
    private func showNetworkError(message: String) {
        hideLoadingIndicator()

        let model = AlertModel(
            title: "Ошибка",
            message: message,
            buttonText: "Попробовать ещё раз"
        ) { [weak self] in
            self?.restartGame()
        }

        alertPresenter.show(in: self, model: model)
    }
}
