//
//  Copyright © 2018 Essential Developer. All rights reserved.
//

import Foundation

public final class RemoteFeedLoader: FeedLoader {
	private let url: URL
	private let client: HTTPClient
	
	public enum Error: Swift.Error {
		case connectivity
		case invalidData
	}
		
	public init(url: URL, client: HTTPClient) {
		self.url = url
		self.client = client
	}
	
	public func load(completion: @escaping (FeedLoader.Result) -> Void) {
        client.get(from: url) { [weak self] result in
            guard self != nil else { return }
            switch result {
            case .failure:
                completion(.failure(RemoteFeedLoader.Error.connectivity))
            case let .success((data, response)):
                let result = FeedImagesMapper.map(data, response)
                completion(result)
            }
        }
    }
}

private class FeedImagesMapper {
    
    private struct Root: Decodable {
        
        struct ImageItem: Decodable {
            let id: UUID
            let description: String?
            let location: String?
            let imageURL: URL
            
            enum CodingKeys: String, CodingKey {
                case id = "image_id"
                case description = "image_desc"
                case location = "image_loc"
                case imageURL = "image_url"
            }
            
            var feedImage: FeedImage {
                return FeedImage(id: id, description: description, location: location, url: imageURL)
            }
        }
        
        var items: [ImageItem]
    }
    
    static func map(_ data: Data, _ response: HTTPURLResponse) -> Result<[FeedImage], Error> {
        guard response.statusCode == 200,
              let root = try? JSONDecoder().decode(Root.self, from: data) else {
            return .failure(RemoteFeedLoader.Error.invalidData)
        }
        
        let items = root.items.map {$0.feedImage}
        return .success(items)
    }
    
}
