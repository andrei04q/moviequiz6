import Foundation

final class QuestionFactory: QuestionFactoryProtocol {
    private let moviesLoader: MoviesLoading
    private weak var delegate: QuestionFactoryDelegate?

    private var movies: [MostPopularMovie] = []

    init(moviesLoader: MoviesLoading, delegate: QuestionFactoryDelegate?) {
        self.moviesLoader = moviesLoader
        self.delegate = delegate
    }

    func loadData() {
        moviesLoader.loadMovies { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }

                switch result {
                case .success(let mostPopularMovies):
                    self.movies = mostPopularMovies.items
                    print("✅ Успешно загружено фильмов: \(self.movies.count)")
                    self.delegate?.didLoadDataFromServer()
                case .failure(let error):
                    print("❌ Ошибка загрузки фильмов: \(error.localizedDescription)")
                    self.delegate?.didFailToLoadData(with: error)
                }
            }
        }
    }

    func requestNextQuestion() {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }

            if self.movies.isEmpty {
                print("❌ Movies array is empty")
                return
            }

            let index = (0..<self.movies.count).randomElement() ?? 0
            guard let movie = self.movies[safe: index] else {
                print("❌ Movie at index \(index) not found")
                return
            }

            var imageData = Data()
            do {
                imageData = try Data(contentsOf: movie.resizedImageURL)
                print("✅ Успешно загружено изображение из: \(movie.resizedImageURL)")
            } catch {
                print("❌ Не удалось загрузить изображение: \(error.localizedDescription)")
                return
            }

            guard !imageData.isEmpty else {
                print("❌ Получены пустые данные изображения")
                return
            }

            let rating = Float(movie.rating) ?? 0
            let text = "Рейтинг этого фильма больше, чем 7?"
            let correctAnswer = rating > 7

            let question = QuizQuestion(
                image: imageData,
                text: text,
                correctAnswer: correctAnswer
            )

            DispatchQueue.main.async { [weak self] in
                self?.delegate?.didReceiveNextQuestion(question: question)
            }
        }
    }
}
