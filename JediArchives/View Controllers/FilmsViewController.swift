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

class FilmsViewController: UITableViewController {

  let dataSource = ListDataSource()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    configure()
    loadFilms()
  }

  func configure() {
    applyDarkStyle()
    navigationItem.largeTitleDisplayMode = .always
    navigationController?.navigationBar.prefersLargeTitles = true
    dataSource.configure(with: tableView)
  }
}

// MARK: Table View

extension FilmsViewController {

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

extension FilmsViewController {

  func loadFilms() {
    // [1] - execute the AllFilms query by passing an instance of it to the
    // shared Apollo client. ApolloClient translates the query to JSON,
    // executes the HTTP call, maps the response to the generated structs,
    // and invokes the provided completion handler with either result data
    // or an error if there was a failure.
    let query = AllFilmsQuery()
    Apollo.shared.client.fetch(query: query) { result in
      switch result {
      case .success(let graphQLResult):
        // [2] - unwrap a chain of optionals and compactMap to produce a
        // list of film results. If you inspect the type of results?.data?.allFilms?.films,
        // you’ll see it’s [Film?]?. Therefore compactMap is used to produce a list without optional objects.
        if let films = graphQLResult.data?.allFilms?.films?.compactMap({$0}) {
          // [3] - map the film results to RefItem.
          let models = films.map(RefItem.init)
          // [4] - create a list of Section enums that represent the sections displayed in the table view.
          // In this case there is just one section of films.
          let sections: [Section] = [
            .references(title: NSLocalizedString("Films", comment: ""), models: models)
          ]

          // [5] - set the list of sections on the table view’s data source and
          // reload the table view to render the data to the screen.
          self.dataSource.sections = sections
          self.tableView.reloadData()
        } else if let errors = graphQLResult.errors {
          // GraphQL errors
          print("Errors: \(errors)")
        }
      case .failure(let error):
        // Network or response format errors
        print("Error loading data \(error)")
      }
    }
  }
}
