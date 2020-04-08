//    @objc func dispatchUpdateStatus() {
//        DispatchQueue.main.async {
//            var status = ""
//            do {
////                (self.artist, self.track) = try SpotifyApi.getArtistAndTitle()
//                self.sanitzeTrackInfo()
//                status = "\(self.track) by \(self.artist)"
////                self.statusMenuItem.action = #selector(self.getLyrics)
//            } catch {
//                status = "Couldn't fetch data from Spotify"
//                self.statusMenuItem.action = nil
//            }
//
//            Swift.print(status)
//            self.statusMenuItem.title = status
//        }
//    }

//    func sanitzeTrackInfo() {
//        self.artist = self.sanitizeValue(self.artist)
//        self.track = self.sanitizeValue(self.track)
//    }

//    func sanitizeValue(_ val: String) -> String {
//        var str = val
////        let regex = try! NSRegularExpression(pattern: "", options: NSRegularExpression.Options.caseInsensitive)
////
////        let range = NSMakeRange(0, str.count)
////        let modString = regex.stringByReplacingMatches(in: str, options: [], range: range, withTemplate: "")
//        if let range = val.lowercased().range(of: " (feat.") {
//            str = String(val.prefix(upTo: range.lowerBound))
//        } else if let range = val.lowercased().range(of: " feat.") {
//            str = String(val.prefix(upTo: range.lowerBound))
//        }
//        return str
//
//    }
