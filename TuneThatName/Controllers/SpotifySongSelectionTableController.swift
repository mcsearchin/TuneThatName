import UIKit

public class SpotifySongSelectionTableController: UITableViewController, SpotifyPlaybackDelegate {
    
    public var searchContact: Contact!
    public var songSelectionCompletionHandler: ((Song, Contact?) -> Void)!
    public var songs = [Song]()
    
    public var echoNestService = EchoNestService()
    public var spotifyAudioFacadeOverride: SpotifyAudioFacade!
    lazy var spotifyAudioFacade: SpotifyAudioFacade! = {
        return self.spotifyAudioFacadeOverride != nil ? self.spotifyAudioFacadeOverride : SpotifyAudioFacadeImpl.sharedInstance
        }()
    public var spotifyUserService = SpotifyUserService()
    public var controllerHelper = ControllerHelper()
    
    lazy var activityIndicator: UIActivityIndicatorView = ControllerHelper.newActivityIndicatorForView(self.navigationController!.view)
    
    @IBOutlet public weak var selectButton: UIBarButtonItem!
    @IBOutlet public weak var playPauseButton: UIBarButtonItem!
    @IBOutlet public weak var songViewButton: UIBarButtonItem!
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        clearsSelectionOnViewWillAppear = false
        selectButton.enabled = false
        populateSongs()
    }
    
    override public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        spotifyAudioFacade.playbackDelegate = self
        
        self.navigationController?.setToolbarHidden(false, animated: animated)
    }
    
    override public func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setToolbarHidden(true, animated: animated)
    }
    
    func populateSongs() {
        ControllerHelper.handleBeginBackgroundActivityForView(view, activityIndicator: activityIndicator)
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            self.spotifyUserService.retrieveCurrentUser() {
                userResult in
                
                self.handleUserResult(userResult) {
                    user in
                    
                    self.echoNestService.findSongs(titleSearchTerm: self.searchContact.searchString,
                        withSongPreferences: SongPreferences(),
                        desiredNumberOfSongs: 50, inLocale: user.territory) {
                        songsResult in
                        
                        self.handleSongsResult(songsResult)
                    }
                }
            }
        }
    }
    
    func handleUserResult(userResult: SpotifyUserService.UserResult, userResultSuccessHandler: SpotifyUser -> Void) {
        switch (userResult) {
        case .Success(let user):
            userResultSuccessHandler(user)
        case .Failure(let error):
            dispatch_async(dispatch_get_main_queue()) {
                
                ControllerHelper.displaySimpleAlertForTitle(Constants.Error.GenericSongSearchMessage, andError: error, onController: self)
                ControllerHelper.handleCompleteBackgroundActivityForView(self.view, activityIndicator: self.activityIndicator)
            }
        }
    }
    
    func handleSongsResult(songsResult: EchoNestService.SongsResult) {
        dispatch_async(dispatch_get_main_queue()) {
            switch (songsResult) {
                
            case .Success(let songs):
                if !songs.isEmpty {
                    self.songs = songs
                    self.tableView.reloadData()
                } else {
                    self.handleSongSearchFailureForNoSongsFound()
                }
            case .Failure(let error):
                if Constants.Error.Domain == error.domain && Constants.Error.EchonestUnknownErrorCode == error.code {
                    self.handleSongSearchFailureForNoSongsFound()
                } else {
                    self.handleSongSearchFailureWithTitle(Constants.Error.GenericSongSearchMessage, andMessage: error.localizedDescription)
                }
            }
            
            ControllerHelper.handleCompleteBackgroundActivityForView(self.view, activityIndicator: self.activityIndicator)
        }
    }
    
    func handleSongSearchFailureForNoSongsFound() {
        handleSongSearchFailureWithTitle("No Songs Found\nfor \"\(self.searchContact.searchString)\"",
            andMessage: "Try searching with a different name. Results are best when you use only a first name."
        )
    }
    
    func handleSongSearchFailureWithTitle(title: String, andMessage message: String) {
        ControllerHelper.displaySimpleAlertForTitle(title, andMessage: message, onController: self) {
            alertAction in
            
            self.navigationController?.popViewControllerAnimated(true)
        }
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

    override public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return songs.count
    }

    override public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("SongSelectionTableCell", forIndexPath: indexPath) 
        
        let song = songs[indexPath.row]
        cell.textLabel?.text = song.title
        cell.detailTextLabel?.text = song.displayArtistName

        return cell
    }
    
    override public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectButton.enabled = true
        playFromIndex(indexPath.row)
    }
    
    func playFromIndex(index: Int) {
        let song = songs[index]
        
        ControllerHelper.handleBeginBackgroundActivityForView(view, activityIndicator: activityIndicator)
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            self.spotifyAudioFacade.playTracksForURIs([song.uri], fromIndex: 0) {
                error in
                
                dispatch_async(dispatch_get_main_queue()) {
                    if error != nil && error.code != Constants.Error.SpotifyLoginCanceledCode {
                        ControllerHelper.displaySimpleAlertForTitle(Constants.Error.GenericPlaybackMessage, andError: error, onController: self)
                    }
                    ControllerHelper.handleCompleteBackgroundActivityForView(self.view, activityIndicator: self.activityIndicator)
                }
            }
        }
    }
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    // MARK: - Navigation

    override public func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let destinationViewController: AnyObject = segue.destinationViewController
        if let spotifyTrackViewController = destinationViewController as? SpotifyTrackViewController {
            spotifyTrackViewController.spotifyAudioFacade = spotifyAudioFacade
            spotifyTrackViewController.hidePreviousAndNextTrackButtons = true
        }
    }
    
    @IBAction func cancelPressed(sender: UIBarButtonItem) {
        navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func selectPressed(sender: UIBarButtonItem) {
        let selectedSong = songs[tableView.indexPathForSelectedRow!.row]
        songSelectionCompletionHandler(selectedSong, searchContact)
    }
    
    @IBAction func playPausePressed(sender: UIBarButtonItem) {
        if spotifyAudioFacade.currentSpotifyTrack != nil {
            spotifyAudioFacade.togglePlay() {
                error in
                if error != nil {
                    ControllerHelper.displaySimpleAlertForTitle(Constants.Error.GenericPlaybackMessage, andError: error, onController: self)
                }
            }
        } else {
            playFromIndex(0)
        }
    }
    
    public func changedPlaybackStatus(isPlaying: Bool) {
        ControllerHelper.updatePlayPauseButtonOnTarget(self, withAction: "playPausePressed:", forIsPlaying: isPlaying)
    }
    
    public func changedCurrentTrack(spotifyTrack: SpotifyTrack?) {
        selectRowForSpotifyTrack(spotifyTrack)
        updateSongViewButtonForTrack(spotifyTrack)
    }
    
    func selectRowForSpotifyTrack(spotifyTrack: SpotifyTrack?) {
        if let index = ControllerHelper.getIndexForSpotifyTrack(spotifyTrack, inSongs: songs) {
            self.tableView.selectRowAtIndexPath(NSIndexPath(forRow: index, inSection: 0), animated: false, scrollPosition: UITableViewScrollPosition.None)
        }
    }
    
    func updateSongViewButtonForTrack(spotifyTrack: SpotifyTrack?) {
        if let albumImageURL = spotifyTrack?.albumSmallestCoverImageURL {
            controllerHelper.getImageForURL(albumImageURL) {
                image in
                self.updateSongViewButtonForImage(image)
            }
        } else {
            updateSongViewButtonForImage(nil)
        }
    }
    
    func updateSongViewButtonForImage(image: UIImage?) {
        ControllerHelper.updateBarButtonItemOnTarget(self, action: "songViewPressed:", atToolbarIndex: 0, withImage: image)
    }
    
    @IBAction func songViewPressed(sender: UIBarButtonItem) {
        performSegueWithIdentifier("ShowSpotifyTrackFromSongSelectionSegue", sender: nil)
    }
}
