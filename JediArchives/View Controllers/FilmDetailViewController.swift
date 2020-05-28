/// Copyright (c) 2018 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit

class FilmDetailViewController: UITableViewController {

  let filmID: String
  let dataSource = ListDataSource()

  init(filmID: String) {
    self.filmID = filmID
    super.init(style: .grouped)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    configure()
    loadFilmDetail()
  }

  func configure() {
    applyDarkStyle()
    dataSource.configure(with: tableView)
  }
}

// MARK: Table View
extension FilmDetailViewController {

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    switch dataSource.sections[indexPath.section] {
    case .references(_, let models):
      let model = models[indexPath.row]
      let detailVC = CharacterDetailViewController(characterID: model.id)
      navigationController?.pushViewController(detailVC, animated: true)
    default:
      break
    }
  }
}

// MARK: Data
extension FilmDetailViewController {

  func loadFilmDetail() {
    // 1 Create an instance of FilmDetailQuery and pass the ID for the film
    // this view controller should display. With that query object,
    // you execute the fetch via the Apollo client.
    let query = FilmDetailQuery(id: filmID)

    Apollo.shared.client.fetch(query: query) { result in
      switch result {
      case .success(let graphQLResult):
        // 2 Use optional binding to get the film from the query result.
        if let film = graphQLResult.data?.film {

          // 3 Set the title of the screen to the name of the film.
          self.navigationItem.title = film.title ?? ""

          // 4 create a list of InfoItem models to represent each attribute
          // of the film you want to render to the UI. Each item has a title
          // and value, and there is some nil coalescing to account for missing values.
          let infoItems: [InfoItem] = [
            InfoItem(label: NSLocalizedString("Title", comment: ""), value: film.title ?? "NA"),
            InfoItem(label: NSLocalizedString("Episode", comment: ""), value: "\(film.episodeId ?? 0)"),
            InfoItem(label: NSLocalizedString("Released", comment: ""), value: film.releaseDate ?? "NA"),
            InfoItem(label: NSLocalizedString("Director", comment: ""), value: film.director ?? "NA")
          ]

          // 5 Define a Section for the film info section, providing the list of info items you just created.
          var sections: [Section] = [
            .info(title: NSLocalizedString("Info", comment: ""), models: infoItems)
          ]

          // 6 Second section of this detail screen is a list of characters that appear
          // in this film. You map the character list from the film result to a list of RefItem objects.

          let characterItems = film.characterConnection?.characters?
            .compactMap({$0}).map({RefItem(character: $0)})

          // 7 Create a new Section, to show the character items.
          if let characterItems = characterItems, characterItems.count > 0 {
            sections.append(.references(title: NSLocalizedString("Characters", comment: ""),
                                        models: characterItems))
          }

          // 8 Update the data source and reload the table view to render the data.
          self.dataSource.sections = sections
          self.tableView.reloadData()
        } else if let errors = graphQLResult.errors {
          // GraphQL errors.
          print("Errors: \(errors)")
        }
      case .failure(let error):
        // Network or response format errors.
        print("Error loading data \(error)")
      }
    }
  }
}
