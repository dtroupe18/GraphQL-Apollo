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

class CharacterDetailViewController: UITableViewController {

  let characterID: String
  let dataSource = ListDataSource()

  init(characterID: String) {
    self.characterID = characterID
    super.init(style: .grouped)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    configure()
    loadCharacter()
  }

  func configure() {
    applyDarkStyle()
    dataSource.configure(with: tableView)
  }
}

// MARK: Table View
extension CharacterDetailViewController {

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    switch dataSource.sections[indexPath.section] {
    case .references(_, let models):
      let model = models[indexPath.row]
      let detailVC = FilmDetailViewController(filmID: model.id)
      navigationController?.pushViewController(detailVC, animated: true)
    default:
      break
    }
  }
}

// MARK: Data
extension CharacterDetailViewController {

  func loadCharacter() {
    // 1 Initialize and execute CharacterDetailQuery, providing the character ID.
    let query = CharacterDetailQuery(id: characterID)

    Apollo.shared.client.fetch(query: query) { result in
      switch result {
      case .success(let graphQLResult):
        // 2 optional binding to get the character from the result object.
        if let character = graphQLResult.data?.person {
          // 3 set the title of the view controller to the character’s name.
          self.navigationItem.title = character.name ?? ""

          // 4 create a list of InfoItem objects to represent the various character attributes you requested.
          let infoItems: [InfoItem] = [
            InfoItem(label: NSLocalizedString("Name", comment: ""),
                     value: character.name ?? "NA"),
            InfoItem(label: NSLocalizedString("Birth Year", comment: ""),
                     value: character.birthYear ?? "NA"),
            InfoItem(label: NSLocalizedString("Eye Color", comment: ""),
                     value: character.eyeColor ?? "NA"),
            InfoItem(label: NSLocalizedString("Gender", comment: ""),
                     value: character.gender ?? "NA"),
            InfoItem(label: NSLocalizedString("Hair Color", comment: ""),
                     value: character.hairColor ?? "NA"),
            InfoItem(label: NSLocalizedString("Skin Color", comment: ""),
                     value: character.skinColor ?? "NA"),
            InfoItem(label: NSLocalizedString("Home World", comment: ""),
                     value: character.homeworld?.name ?? "NA")
          ]

          // 5 create the first table view section, passing the InfoItem objects as the contents.
          var sections: [Section] = [
            .info(title: NSLocalizedString("Info", comment: ""), models: infoItems)
          ]

          // 6 make use of the films, again using the ListFilmFragment,
          // to populate a table view section with films this character has appeared in.
          let filmItems = character.filmConnection?.films?.compactMap({$0})
            .map({RefItem(film: $0.fragments.listFilmFragment)})
          if let filmItems = filmItems, filmItems.count > 0 {
            sections.append(.references(title: NSLocalizedString("Appears In", comment: ""),
                                        models: filmItems))
          }

          // 7 update the data source’s section list and reload the table view to render the new data to the UI.
          self.dataSource.sections = sections
          self.tableView.reloadData()
        } else if let error = graphQLResult.errors {
          print("Error loading data \(error)")
        }
      case .failure(let error):
        // Network or response format errors.
        print("Error loading data \(error)")
      }
    }
  }
}
