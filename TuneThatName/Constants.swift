import Foundation

public struct Constants {
    
    public struct Error {
        public static let Domain = "com.mcsearchin.TuneThatName"
        
        public static let AddressBookNoAccessCode = 10
        public static let AddressBookNoAccessMessage = "Access has been denied. " +
            "Please go to settings and allow \"Tune That Name\" to access your Contacts."
        
        public static let NoContactsCode = 15
        public static let NoContactsMessage = "You currently have no contacts."
        
        public static let PlaylistGeneralErrorCode = 20
        public static let PlaylistGeneralErrorMessage = "Encountered errors trying to build your playlist. Please try again later."
        
        public static let PlaylistNotEnoughSongsCode = 21
        public static let PlaylistNotEnoughSongsMessage = "Could not find enough songs matching the provided search criteria."
        
        public static let SpotifyNoCurrentTrackCode = 25
        public static let SpotifyNoCurrentTrackMessage = "There is no track in the current session."
        
        public static let SpotifyLoginCanceledCode = 30
        public static let SpotifyLoginCanceledMessage = "Login to spotify was canceled."
        
        public static let EchoNestGeneralErrorCode = 40
        public static let EchonestUnknownErrorCode = 41
        
        public static let GenericPlaybackMessage = "Unable to Play Song"
        public static let GenericSongSearchMessage = "Unable to Search for Songs"
    }
    
    public struct StorageKeys {
        public static let filteredContacts = "TuneThatName.contacts.filtered"
        public static let playlistPreferences = "TuneThatName.playlist.preferences"
        public static let presentedInitialHelp = "TuneThatName.presentedInitialHelp"
        public static let spotifyCurrentUser = "TuneThatName.spotify.currentUser"
    }
}