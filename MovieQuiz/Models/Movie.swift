import UIKit

struct Movie: Codable {
    let id: String
    let rank: String
    let title: String
    let fullTitle: String
    let year: String
    let image: String
    let crew: String
    let imDbRating: String
    let imDbRatingCount: String
}

struct Top: Codable {
    let items: [Movie]
}

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadMoviesFromJSON()
    }

    
    func loadMoviesFromJSON() {
        if let url = Bundle.main.url(forResource: "top250MoviesIMDB", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let decodedData = try JSONDecoder().decode(Top.self, from: data)
                
                let movies = decodedData.items
                print("✅ Загружено фильмов: \(movies.count)")
                print("🎬 Первый фильм: \(movies.first?.title ?? "Нет данных")")
            } catch {
                print("❌ Ошибка при парсинге: \(error)")
            }
        } else {
            print("❌ Файл не найден")
        }
    }
}

