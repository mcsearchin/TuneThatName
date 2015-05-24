import UIKit

public class SpotifyPlaylistTableController: UITableViewController, SPTAuthViewDelegate, SPTAudioStreamingPlaybackDelegate {
    
    public enum SpotifyPostLoginAction {
        case PlayPlaylist(index: Int)
        case SavePlaylist
    }
    
    let playSongErrorTitle = "Unable to Play Song"
    
    public var playlist: Playlist!
    public var spotifyPostLoginAction: SpotifyPostLoginAction!
    var played = false
    var songView: SongView?
    
    public var spotifyAuth: SPTAuth! = SPTAuth.defaultInstance()
    var spotifyAuthController: SPTAuthViewController!
    
    public var spotifyService = SpotifyService()
    public var spotifyAudioFacadeOverride: SpotifyAudioFacade!
    lazy var spotifyAudioFacade: SpotifyAudioFacade! = {
        return self.spotifyAudioFacadeOverride != nil ? self.spotifyAudioFacadeOverride : SpotifyAudioFacadeImpl(spotifyPlaybackDelegate: self)
    }()

    lazy var activityIndicator: UIActivityIndicatorView = ControllerHelper.newActivityIndicatorForView(self.tableView)
    
    @IBOutlet public weak var saveButton: UIBarButtonItem!
    
    @IBOutlet public weak var playPauseButton: UIBarButtonItem!
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        played = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        updateSaveButtonForUnsavedPlaylist()
    }
    
    override public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setToolbarHidden(false, animated: animated)
    }

    override public func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setToolbarHidden(true, animated: animated)
        
        spotifyAudioFacade.stopPlay() {
            error in
            if error != nil {
                print("Error stopping play: \(error)")
            }
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
        return playlist.songs.count
    }

    override public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("PlaylistTableCell", forIndexPath: indexPath) as! UITableViewCell

        let song = playlist.songs[indexPath.row]
        cell.textLabel?.text = song.title
        cell.detailTextLabel?.text = song.artistName

        return cell
    }
    
    override public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        playFromIndex(indexPath.row)
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override public func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */
    
    
    @IBAction public func savePlaylistPressed(sender: AnyObject) {
        if sessionIsValid() {
            savePlaylist()
        } else {
            openLogin(SpotifyPostLoginAction.SavePlaylist)
        }
    }
    
    func sessionIsValid() -> Bool {
        return spotifyAuth.session != nil && spotifyAuth.session.isValid()
    }
    
    func openLogin(spotifyPostLoginAction: SpotifyPostLoginAction) {
        self.spotifyPostLoginAction = spotifyPostLoginAction

        spotifyAuthController = SPTAuthViewController.authenticationViewControllerWithAuth(spotifyAuth)
        spotifyAuthController.delegate = self
        spotifyAuthController.modalPresentationStyle = UIModalPresentationStyle.CurrentContext
        spotifyAuthController.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
        
        self.modalPresentationStyle = UIModalPresentationStyle.CurrentContext
        self.definesPresentationContext = true
        
        presentViewController(self.spotifyAuthController, animated: false, completion: nil)
    }
    
    public func authenticationViewController(viewController: SPTAuthViewController, didFailToLogin error: NSError) {
        println("Login failed... error: \(error)")
    }
    
    public func authenticationViewController(viewController: SPTAuthViewController, didLoginWithSession session: SPTSession) {
        println("Login succeeded... session: \(session)")
        switch (spotifyPostLoginAction!) {
        case .PlayPlaylist(let index):
            playFromIndex(index)
        case .SavePlaylist:
            savePlaylist()
        }
    }
    
    public func authenticationViewControllerDidCancelLogin(viewController: SPTAuthViewController) {
    }
    
    func savePlaylist() {
        updateSaveButtonForPlaylistSaveInProgress()
        ControllerHelper.handleBeginBackgroundActivityForView(view, activityIndicator: activityIndicator)
        let session = spotifyAuth.session
        println("access token: \(session?.accessToken)")
        dispatch_async(dispatch_get_main_queue()) {
            self.spotifyService.savePlaylist(self.playlist, session: session) {
                playlistResult in
                
                switch (playlistResult) {
                case .Success(let playlist):
                    self.playlist = playlist
                    self.updateSaveButtonAfterPlaylistSaved()
                case .Failure(let error):
                    println("Error saving playlist: \(error)")
                    ControllerHelper.displaySimpleAlertForTitle("Unable to Save Your Playlist", andError: error, onController: self)
                }
                ControllerHelper.handleCompleteBackgroundActivityForView(self.view, activityIndicator: self.activityIndicator)
            }
        }
    }
    
    func updateSaveButtonForUnsavedPlaylist() {
        self.saveButton.title = "Save to Spotify"
        self.saveButton.enabled = true
    }
    
    func updateSaveButtonForPlaylistSaveInProgress() {
        self.saveButton.title = "Saving Playlist"
        self.saveButton.enabled = false
    }
    
    func updateSaveButtonAfterPlaylistSaved() {
        self.saveButton.title = "Playlist Saved"
        self.saveButton.enabled = false
    }
    
    @IBAction func playPausePressed(sender: UIBarButtonItem) {
        if !played {
            playFromIndex(0)
        } else {
            spotifyAudioFacade.togglePlay() {
                error in
                if error != nil {
                    ControllerHelper.displaySimpleAlertForTitle(self.playSongErrorTitle, andError: error, onController: self)
                }
            }
        }
    }
    
    func playFromIndex(index: Int) {
        if sessionIsValid() {
            ControllerHelper.handleBeginBackgroundActivityForView(view, activityIndicator: activityIndicator)
            
            spotifyAudioFacade.playPlaylist(self.playlist, fromIndex: index, inSession: spotifyAuth.session) {
                error in
                if error != nil {
                    ControllerHelper.displaySimpleAlertForTitle(self.playSongErrorTitle, andError: error, onController: self)
                } else {
                    self.played = true
                    self.displaySongView()
                }
                ControllerHelper.handleCompleteBackgroundActivityForView(self.view, activityIndicator: self.activityIndicator)
            }
        } else {
            openLogin(SpotifyPostLoginAction.PlayPlaylist(index: index))
        }
    }
    
    func displaySongView() {
        spotifyAudioFacade.getCurrentTrackInSession(spotifyAuth.session) {
            (error, track) in
            
            if error != nil {
                print("Error getting track : \(error)")
            } else {
                let currentTrack = track as! SPTTrack

                self.songView = (NSBundle.mainBundle().loadNibNamed("SongView", owner: self, options: nil).first as! SongView)
                self.view.addSubview(self.songView!)
                self.songView!.frame = self.view.bounds
                self.printViewStuff(self.view, name: "self.view")
                self.printViewStuff(self.navigationController!.view, name: "navigationController!.view")
                self.printViewStuff(self.songView!, name: "songView")
                
                self.songView!.title.text = currentTrack.name
                self.songView!.artist.text = currentTrack.artists?.first?.name
                self.songView!.album.text = currentTrack.album?.name
                dispatch_async(dispatch_get_main_queue()) {
                    let albumImage = ControllerHelper.getImageForURL(currentTrack.album.largestCover.imageURL)
                    self.songView!.image.image = albumImage
                }
            }
        }
    }
    
    func printViewStuff(view: UIView, name: String) {
        println("\(name) bounds x = \(view.bounds.origin.x)")
        println("\(name) bounds y = \(view.bounds.origin.y)")
        println("\(name) bounds width = \(view.bounds.size.width)")
        println("\(name) bounds height = \(view.bounds.size.height)")
        println("\(name) frame x = \(view.frame.origin.x)")
        println("\(name) frame y = \(view.frame.origin.y)")
        println("\(name) frame width = \(view.frame.size.width)")
        println("\(name) frame height = \(view.frame.size.height)")
        println("\(name) center = \(view.center)")
    }
    
    public func audioStreaming(audioStreaming: SPTAudioStreamingController!,
        didChangePlaybackStatus isPlaying: Bool) {
        updatePlayPauseButton(isPlaying)
    }
    
    func updatePlayPauseButton(isPlaying: Bool) {
        let buttonSystemItem = isPlaying ? UIBarButtonSystemItem.Pause : UIBarButtonSystemItem.Play
        let updatedButton = UIBarButtonItem(barButtonSystemItem: buttonSystemItem, target: self, action: "playPausePressed:")
        self.navigationController?.toolbar.items?.removeLast()
        self.navigationController?.toolbar.items?.append(updatedButton)
    }
    
    public func audioStreaming(audioStreaming: SPTAudioStreamingController!, didStartPlayingTrack trackUri: NSURL!) {
        self.tableView.selectRowAtIndexPath(NSIndexPath(forRow: Int(audioStreaming.currentTrackIndex), inSection: 0), animated: false, scrollPosition: UITableViewScrollPosition.Middle)
    }
}
