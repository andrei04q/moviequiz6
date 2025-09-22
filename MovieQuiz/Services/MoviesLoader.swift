import Foundation

protocol MoviesLoading {
    func loadMovies(handler: @escaping (Result<MostPopularMovies, Error>) -> Void)
}

struct MoviesLoader: MoviesLoading {
    private let networkClient = NetworkClient()
    
    // ✅ Исправленный URL: официальный IMDb API
    private var mostPopularMoviesUrl: URL {
        guard let url = URL(string: "https://imdb-api.com/en/API/Top250Movies/k_kiwxbi4y") else {
            fatalError("❌ Invalid IMDb API URL")
        }
        return url
    }
    func loadMovies(handler: @escaping (Result<MostPopularMovies, Error>) -> Void) {
        print("🌐 Загружаем фильмы с: \(mostPopularMoviesUrl)")
        
        networkClient.fetch(url: mostPopularMoviesUrl) { result in
            switch result {
            case .success(let data):
                do {
                    let mostPopularMovies = try JSONDecoder().decode(MostPopularMovies.self, from: data)
                    print("✅ Успешно загружено фильмов: \(mostPopularMovies.items.count)")
                    handler(.success(mostPopularMovies))
                } catch {
                    print("❌ Ошибка декодирования JSON: \(error)")
                    handler(.failure(error))
                }
            case .failure(let error):
                print("❌ Ошибка сети при загрузке фильмов: \(error)")
                handler(.failure(error))
            }
        }
    }
}
