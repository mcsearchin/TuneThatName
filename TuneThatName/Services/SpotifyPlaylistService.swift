import Foundation

public class SpotifyPlaylistService {
    
    public enum PlaylistResult {
        case Success(Playlist)
        case Failure(NSError)
        case Canceled
    }
    
    let trackMaxBatchSize = 34
    
    let spotifyAuthService: SpotifyAuthService
    
    public init(spotifyAuthService: SpotifyAuthService = SpotifyAuthService()) {
        self.spotifyAuthService = spotifyAuthService
    }
    
    public func savePlaylist(playlist: Playlist, callback: (PlaylistResult) -> Void) {
        handleAuthenticationForCallback(callback) {
            session in

            if playlist.uri != nil {
                self.updatePlaylist(playlist, session: session, callback: callback)
            } else {
                self.createPlaylist(playlist, session: session, callback: callback)
            }
        }
    }
    
    func createPlaylist(playlist: Playlist, session: SPTSession, callback: (PlaylistResult) -> Void) {
        SPTPlaylistList.createPlaylistWithName(playlist.name, publicFlag: false, session: session) {
            (error, spotifyPlaylistSnapshot) in
            
            if error != nil {
                callback(.Failure(error))
            } else {
                self.addTracksForURIs(playlist.songURIs,
                    toSpotifyPlaylistSnapshot: spotifyPlaylistSnapshot,
                    andResultPlaylist: Playlist(name: spotifyPlaylistSnapshot.name, uri: spotifyPlaylistSnapshot.uri,
                        songsWithContacts: playlist.songsWithContacts),
                    withSession: session,
                    callback: callback)
            }
        }
    }
    
    func updatePlaylist(playlist: Playlist, session: SPTSession, callback: (PlaylistResult) -> Void) {
        SPTPlaylistSnapshot.playlistWithURI(playlist.uri!, session: session) {
            (error, result) in
            
            if error != nil {
                callback(.Failure(error))
            } else if let spotifyPlaylistSnapshot = result as? SPTPlaylistSnapshot {
                self.updatePlaylistName(playlist.name!, forPlaylistSnapshot: spotifyPlaylistSnapshot, inSession: session)
                self.replaceTracksForURIs(playlist.songURIs,
                    inSpotifyPlaylistSnapshot: spotifyPlaylistSnapshot,
                    andResultPlaylist: Playlist(name: playlist.name!, uri: playlist.uri!,
                        songsWithContacts: playlist.songsWithContacts),
                    withSession: session,
                    callback: callback)
            } else {
                callback(.Failure(self.errorForMessage("Unable to retrieve existing playlist", andFailureReason: "Playlist snapshot was nil")))
            }
        }
    }

    func addTracksForURIs(uris: [NSURL],
        toSpotifyPlaylistSnapshot spotifyPlaylistSnapshot: SPTPlaylistSnapshot,
        var andResultPlaylist resultPlaylist: Playlist,
        withSession session: SPTSession,
        callback: (PlaylistResult) -> Void) {
            
            SPTTrack.tracksWithURIs(getURIsToAdd(uris), session: session) {
                (error, tracks) in
                
                if error != nil {
                    callback(.Failure(error))
                } else if let tracks = tracks as? [SPTTrack] {
                    
                    spotifyPlaylistSnapshot.addTracksToPlaylist(tracks, withSession: session) {
                        error in
                        
                        if error != nil {
                            callback(.Failure(error))
                        } else {
                            self.updateSongsForSPTTracks(tracks, inPlaylist: resultPlaylist)
                            let remainingURIs = self.getRemainingURIS(uris)
                            if remainingURIs.isEmpty {
                                callback(.Success(resultPlaylist))
                            } else {
                                self.addTracksForURIs(remainingURIs,
                                    toSpotifyPlaylistSnapshot: spotifyPlaylistSnapshot,
                                    andResultPlaylist: resultPlaylist,
                                    withSession: session,
                                    callback: callback)
                            }
                        }
                    }
                } else {
                    callback(.Failure(self.errorForNilTracks()))
                }
            }
    }
    
    func replaceTracksForURIs(uris: [NSURL],
        inSpotifyPlaylistSnapshot spotifyPlaylistSnapshot: SPTPlaylistSnapshot,
        var andResultPlaylist resultPlaylist: Playlist,
        withSession session: SPTSession,
        callback: (PlaylistResult) -> Void) {
            
            SPTTrack.tracksWithURIs(getURIsToAdd(uris), session: session) {
                (error, tracks) in
                
                if error != nil {
                    callback(.Failure(error))
                } else if let tracks = tracks as? [SPTTrack] {
                    
                    spotifyPlaylistSnapshot.replaceTracksInPlaylist(tracks, withAccessToken: session.accessToken) {
                        error in
                        
                        if error != nil {
                            callback(.Failure(error))
                        } else {
                            self.updateSongsForSPTTracks(tracks, inPlaylist: resultPlaylist)
                            let remainingURIs = self.getRemainingURIS(uris)
                            if remainingURIs.isEmpty {
                                callback(.Success(resultPlaylist))
                            } else {
                                self.addTracksForURIs(remainingURIs,
                                    toSpotifyPlaylistSnapshot: spotifyPlaylistSnapshot,
                                    andResultPlaylist: resultPlaylist,
                                    withSession: session,
                                    callback: callback)
                            }
                        }
                    }
                } else {
                    callback(.Failure(self.errorForNilTracks()))
                }
            }
    }
    
    func getURIsToAdd(uris: [NSURL]) -> [NSURL] {
        return Array(uris[0..<min(uris.count, trackMaxBatchSize)])
    }
    
    func getRemainingURIS(uris: [NSURL]) -> [NSURL] {
        return Array(uris[min(uris.count, trackMaxBatchSize)..<uris.count])
    }
    
    func updateSongsForSPTTracks(tracks: [SPTTrack], var inPlaylist playlist: Playlist) {
        for track in tracks {
            for (index, song) in playlist.songs.enumerate() {
                if track.uri == song.uri {
                    playlist.songsWithContacts[index].song = songForSPTTrack(track)
                }
            }
        }
    }
    
    func songForSPTTrack(track: SPTTrack) -> Song {
        return Song(title: track.name, artistNames: self.getArtistNamesFromTrack(track), uri: track.uri)
    }
    
    func songsFromSPTTracks(tracks: [SPTTrack]) -> [Song] {
        return tracks.map({ Song(title: $0.name, artistNames: self.getArtistNamesFromTrack($0), uri: $0.uri) })
    }
    
    func errorForNilTracks() -> NSError {
        return errorForMessage("Unable to retrieve tracks to save playlist", andFailureReason: "Retrieved tracks were nil")
    }
    
    func updatePlaylistName(name: String, forPlaylistSnapshot playlistSnapshot: SPTPlaylistSnapshot, inSession session: SPTSession) {
        playlistSnapshot.changePlaylistDetails([SPTPlaylistSnapshotNameKey: name], withAccessToken: session.accessToken) {
            error in
            
            if error != nil {
                print("Error updating playlist name: \(error)")
            }
        }
    }
    
    public func unfollowPlaylistURI(playlistURI: NSURL) {
        handleAuthenticationForCallback(nil) {
            session in
            
            do {
                let request = try SPTFollow.createRequestForUnfollowingPlaylist(playlistURI, withAccessToken: session.accessToken)
                SPTRequest.sharedHandler().performRequest(request) {
                    (error, response, data) in
                    
                    if error != nil {
                        print("Error unfollowing playlist: \(error)")
                    } else if (response as? NSHTTPURLResponse)?.statusCode != 200 {
                        print("Bad response code trying to un-follow playlist: \((response as? NSHTTPURLResponse)?.statusCode)")
                    }
                }
            } catch let error as NSError {
                print("Error while creating request: \(error)")
            }
        }
    }
    
    public func retrievePlaylist(uri: NSURL!, callback: (PlaylistResult) -> Void) {
        handleAuthenticationForCallback(callback) {
            session in
            
            SPTPlaylistSnapshot.playlistWithURI(uri, session: session) {
                (error, playlistSnapshot) in
                
                if error != nil {
                    callback(.Failure(error))
                } else if let playlistSnapshot = playlistSnapshot as? SPTPlaylistSnapshot {
                    var playlist = Playlist(name: playlistSnapshot.name, uri: playlistSnapshot.uri)
                    
                    self.completePlaylistRetrieval(playlist, withPlaylistSnapshotPage: playlistSnapshot.firstTrackPage, withSession: session, callback: callback)
                }
            }
        }
    }
    
    func completePlaylistRetrieval(var playlist: Playlist!, withPlaylistSnapshotPage page: SPTListPage!, withSession session: SPTSession!, callback: (PlaylistResult) -> Void) {
        if let tracks = page.items {
            for track in tracks {
                playlist.songsWithContacts.append((song: Song(title: track.name, artistNames: getArtistNamesFromTrack(track as! SPTTrack), uri: track.uri), contact: nil))
            }
        }
        
        if page.hasNextPage {
            page.requestNextPageWithSession(session) {
                (error, nextPage) in
                if error != nil {
                    callback(.Failure(error))
                } else if let nextPage = nextPage as? SPTListPage {
                    self.completePlaylistRetrieval(playlist, withPlaylistSnapshotPage: nextPage, withSession: session, callback: callback)
                } else {
                    self.errorForMessage("Unable to retrieve playlist", andFailureReason: "SPTPlaylistSnapshot page from Spotify was nil")
                }
            }
        } else {
            callback(.Success(playlist))
        }
    }
    
    func handleAuthenticationForCallback(finalPlaylistResultCallback: (PlaylistResult -> Void)?, authSuccessHandler: SPTSession -> Void) {
            spotifyAuthService.doWithSession() {
                authResult in
                
                switch (authResult) {
                case .Success(let session):
                    authSuccessHandler(session)
                case . Failure(let error):
                    finalPlaylistResultCallback?(.Failure(error))
                case .Canceled:
                    finalPlaylistResultCallback?(.Canceled)
                }
            }
    }
    
    func getArtistNamesFromTrack(sptTrack: SPTTrack) -> [String] {
        return sptTrack.artists.map({ $0.name })
    }
    
    func errorForMessage(message: String, andFailureReason reason: String) -> NSError {
        return NSError(domain: Constants.Error.Domain, code: 0, userInfo: [NSLocalizedDescriptionKey: message, NSLocalizedFailureReasonErrorKey: reason])
    }
}
