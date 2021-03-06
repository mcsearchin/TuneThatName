import TuneThatName
import Quick
import Nimble

class SpotifyPlaylistTableControllerSpec: QuickSpec {
    
    override func spec() {
        describe("SpotifyPlaylistTableController") {
            let playlist = Playlist(name: "about to DROP", 
                songsWithContacts: [(song: Song(title: "Me And Bobby McGee", artistName: "Janis Joplin", uri: NSURL(string: "spotify:track:3RpndSyVypRVcN38z98MvU")!), contact: Contact(id: 1, firstName: "Bobby", lastName: "McGee")),
                    (song: Song(title: "Bobby Brown Goes Down", artistName: "Frank Zappa", uri: NSURL(string: "spotify:track:6WALLlw7klz1BfjlyaBDen")!), contact: nil)])
            let spotifyTrack = SpotifyTrack(
                uri: NSURL(string: "spotify:track:6WALLlw7klz1BfjlyaBDen")!,
                name: "Bobby Brown Goes Down",
                artistNames: ["Frank Zappa"],
                albumName: "Sheik Yerbouti",
                albumLargestCoverImageURL: NSURL(string: "https://i.scdn.co/image/9a4d67719ada036cfd70dbf8e6519bbaa1bba3c8")!,
                albumSmallestCoverImageURL: NSURL(string: "https://i.scdn.co/image/a58609bb6df41d2a3a4e96d8a436bb9176c12d85")!)
            let image = UIImage(named: "yuck.png", inBundle: NSBundle(forClass: SpotifyPlaylistTableControllerSpec.self), compatibleWithTraitCollection: nil)
            
            var spotifyPlaylistTableController: SpotifyPlaylistTableController!
            var navigationController: UINavigationController!
            var mockSpotifyPlaylistService: MockSpotifyPlaylistService!
            var mockSpotifyAudioFacade: MockSpotifyAudioFacade!
            var mockControllerHelper: MockControllerHelper!
            
            beforeEach() {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                
                navigationController = storyboard.instantiateInitialViewController() as! UINavigationController

                spotifyPlaylistTableController = storyboard.instantiateViewControllerWithIdentifier("SpotifyPlaylistTableController") as!  SpotifyPlaylistTableController
                
                spotifyPlaylistTableController.playlist = playlist
                mockSpotifyPlaylistService = MockSpotifyPlaylistService()
                spotifyPlaylistTableController.spotifyPlaylistService = mockSpotifyPlaylistService
                mockSpotifyAudioFacade = MockSpotifyAudioFacade()
                spotifyPlaylistTableController.spotifyAudioFacadeOverride = mockSpotifyAudioFacade
                mockControllerHelper = MockControllerHelper()
                spotifyPlaylistTableController.controllerHelper = mockControllerHelper
                
                navigationController.pushViewController(spotifyPlaylistTableController, animated: false)
                UIApplication.sharedApplication().keyWindow!.rootViewController = navigationController
                self.advanceRunLoopForTimeInterval(0.1)
            }
            
            describe("spotify actions button") {
                var spotifyActionsButton: UIBarButtonItem!
                
                beforeEach() {
                    spotifyActionsButton = spotifyPlaylistTableController.toolbarItems?[1]
                }
                
                it("has the expected image") {
                    let expectedImage = UIImage(named: "Dakirby309-Simply-Styled-Spotify.ico")!
                    expect((spotifyActionsButton?.customView as? UIButton)?.currentBackgroundImage).to(equal(expectedImage))
                }
                
                it("has the expected action") {
                    expect((spotifyActionsButton?.customView as? UIButton)?.actionsForTarget(spotifyPlaylistTableController, forControlEvent: .TouchUpInside)).to(equal(["spotifyActionsPressed:"]))
                }
            }
            
            describe("save button pressed") {
                context("when the playlist has a name") {
                    it("calls the service to save the playlist") {
                        self.pressSaveButton(spotifyPlaylistTableController)
                        
                        expect(mockSpotifyPlaylistService.mocker.getNthCallTo(MockSpotifyPlaylistService.Method.savePlaylist, n: 0)).toEventuallyNot(beEmpty())
                        let playlistParameter = mockSpotifyPlaylistService.mocker.getNthCallTo(MockSpotifyPlaylistService.Method.savePlaylist, n: 0)?.first as? Playlist
                        expect(playlistParameter).to(equal(playlist))
                    }

                    
                    it("updates the save button text") {
                        self.pressSaveButton(spotifyPlaylistTableController)
                        
                        expect(spotifyPlaylistTableController.saveButton.title).to(equal("Saving Playlist"))
                    }
                    
                    it("disables the save button") {
                        spotifyPlaylistTableController.saveButton.enabled = true
                        
                        self.pressSaveButton(spotifyPlaylistTableController)
                        
                        expect(spotifyPlaylistTableController.saveButton.enabled).toNot(beTrue())
                    }
                    
                    it("calls the service to save the playlist") {
                        self.pressSaveButton(spotifyPlaylistTableController)
                        
                        expect(mockSpotifyPlaylistService.mocker.getNthCallTo(MockSpotifyPlaylistService.Method.savePlaylist, n: 0)).toEventuallyNot(beEmpty())
                        let playlistParameter = mockSpotifyPlaylistService.mocker.getNthCallTo(MockSpotifyPlaylistService.Method.savePlaylist, n: 0)?.first as? Playlist
                        expect(playlistParameter).to(equal(playlist))
                    }
                    
                    context("and upon saving the playlist successfully") {
                        let savedPlaylist = Playlist(name: "saved playlist", uri: NSURL(string: "uri"))
                        beforeEach() {
                            mockSpotifyPlaylistService.mocker.prepareForCallTo(MockSpotifyPlaylistService.Method.savePlaylist, returnValue: SpotifyPlaylistService.PlaylistResult.Success(savedPlaylist))
                            
                            self.pressSaveButton(spotifyPlaylistTableController)
                        }
                        
                        it("has the saved playlist") {
                            expect(spotifyPlaylistTableController.playlist).toEventually(equal(savedPlaylist))
                        }
                        
                        it("updates the save button text") {
                            expect(spotifyPlaylistTableController.saveButton.title).toEventually(equal("Playlist Saved"))
                        }
                        
                        it("disables the save button") {
                            expect(spotifyPlaylistTableController.saveButton.enabled).toEventuallyNot(beTrue())
                        }
                    }
                    
                    context("and upon failing to save the playlist") {
                        let error = NSError(domain: "com.spotify.ios", code: 777, userInfo: [NSLocalizedDescriptionKey: "error description"])
                        
                        beforeEach() {
                            mockSpotifyPlaylistService.mocker.prepareForCallTo(MockSpotifyPlaylistService.Method.savePlaylist, returnValue: SpotifyPlaylistService.PlaylistResult.Failure(error))
                            spotifyPlaylistTableController.saveButton.title = "If you click this, you'll get an error."

                            self.pressSaveButton(spotifyPlaylistTableController)
                        }
                        
                        it("updates the save button text") {
                            expect(spotifyPlaylistTableController.saveButton.title)
                                .toEventually(equal("Save to Spotify"))
                        }
                        
                        it("displays the error message in an alert") {
                            self.assertSimpleUIAlertControllerPresentedOnController(spotifyPlaylistTableController, withTitle: "Unable to Save Your Playlist", andMessage: error.localizedDescription)
                        }
                    }
                
                    context("and upon canceling the save") {
                        it("updates the save button text") {
                            spotifyPlaylistTableController.saveButton.title = "You're not gonna follow through with this save, are you..."
                            
                            mockSpotifyPlaylistService.mocker.prepareForCallTo(MockSpotifyPlaylistService.Method.savePlaylist, returnValue: SpotifyPlaylistService.PlaylistResult.Canceled)
                            
                            self.pressSaveButton(spotifyPlaylistTableController)

                            expect(spotifyPlaylistTableController.saveButton.title)
                                .toEventually(equal("Save to Spotify"))
                        }
                    }
                }
                
                context("when the playlist does not have a name") {
                    it("presents the playlist name entry view") {
                        spotifyPlaylistTableController.playlist.name = nil
                        
                        self.pressSaveButton(spotifyPlaylistTableController)
                        
                        expect(spotifyPlaylistTableController.presentedViewController).toEventually(beAnInstanceOf(PlaylistNameEntryController), timeout: 2)
                    }
                }
            }
            
            describe("select a song") {
                let indexPath = NSIndexPath(forRow: 1, inSection: 0)
                
                beforeEach() {
                    mockControllerHelper.mocker.prepareForCallTo(MockControllerHelper.Method.getImageForURL, returnValue: image)
                }
            
                it("calls to play the playlist from the given index") {
                    spotifyPlaylistTableController.tableView(spotifyPlaylistTableController.tableView, didSelectRowAtIndexPath: indexPath)
                    
                    self.verifyCallsToPlayTracksForURIsOn(mockSpotifyAudioFacade, expectedURIs: playlist.songURIs, expectedIndex: indexPath.row)
                }
                
                context("upon playing the playlist") {
                    it("shows the spotify track view") {
                        spotifyPlaylistTableController.tableView(spotifyPlaylistTableController.tableView, didSelectRowAtIndexPath: indexPath)
                        
                        expect(spotifyPlaylistTableController.presentedViewController).toEventually(
                            beAnInstanceOf(SpotifyTrackViewController))
                        let spotifyTrackViewController = spotifyPlaylistTableController.presentedViewController as? SpotifyTrackViewController
                        expect(spotifyTrackViewController?.spotifyAudioFacade as? MockSpotifyAudioFacade).to(beIdenticalTo(mockSpotifyAudioFacade))
                    }
                }
                
                context("upon failing to play the playlist") {
                    let error = NSError(domain: "com.spotify.ios", code: 888, userInfo: [NSLocalizedDescriptionKey: "this list is unplayable"])
                    
                    it("displays the error message in an alert") {
                        mockSpotifyAudioFacade.mocker.prepareForCallTo(
                            MockSpotifyAudioFacade.Method.playTracksForURIs, returnValue: error)
                        
                        spotifyPlaylistTableController.tableView(spotifyPlaylistTableController.tableView, didSelectRowAtIndexPath: indexPath)
                        
                        self.assertSimpleUIAlertControllerPresentedOnController(spotifyPlaylistTableController, withTitle: Constants.Error.GenericPlaybackMessage, andMessage: error.localizedDescription)
                    }
                    
                    context("and the error is due to login cancellation") {
                        let loginCanceledError = NSError(domain: Constants.Error.Domain, code: Constants.Error.SpotifyLoginCanceledCode, userInfo: [:])
                        
                        it("does not present any controller") {
                            mockSpotifyAudioFacade.mocker.prepareForCallTo(
                                MockSpotifyAudioFacade.Method.playTracksForURIs, returnValue: loginCanceledError)
                            
                            spotifyPlaylistTableController.tableView(spotifyPlaylistTableController.tableView, didSelectRowAtIndexPath: indexPath)
                            self.advanceRunLoopForTimeInterval(0.1)
                            
                            expect(spotifyPlaylistTableController.presentedViewController).toEventually(beNil())
                        }
                    }
                }
                
                context("while editing") {
                    it("does not show the spotify track view") {
                        self.pressEditButton(spotifyPlaylistTableController)
                        
                        spotifyPlaylistTableController.tableView(spotifyPlaylistTableController.tableView, didSelectRowAtIndexPath: indexPath)

                        waitUntil() { done in
                            NSThread.sleepForTimeInterval(0.1)
                            done()
                        }
                        expect(spotifyPlaylistTableController.presentedViewController)
                            .toEventually(beNil())
                    }
                }
            }
            
            describe("press the play/pause button") {
                context("and the playlist has not played yet") {
                    it("calls to play the playlist from the first index") {
                        self.pressPlayPauseButton(spotifyPlaylistTableController)
                        
                        self.verifyCallsToPlayTracksForURIsOn(mockSpotifyAudioFacade, expectedURIs: playlist.songURIs, expectedIndex: 0)
                    }
                }
                
                context("when play has already started") {
                    beforeEach() {
                        mockSpotifyAudioFacade.mocker.prepareForCallTo(MockSpotifyAudioFacade.Method.getCurrentSpotifyTrack, returnValue: spotifyTrack)
                    }
                    
                    it("toggles play") {
                        self.pressPlayPauseButton(spotifyPlaylistTableController)
                        
                        expect(mockSpotifyAudioFacade.mocker.getCallCountFor(
                            MockSpotifyAudioFacade.Method.togglePlay)).toEventually(equal(1))
                    }
                    
                    context("and upon failing to toggle play") {
                        let error = NSError(domain: "com.spotify.ios", code: 999, userInfo: [NSLocalizedDescriptionKey: "couldn't toggle play"])
                        
                        it("displays the error message in an alert") {
                            mockSpotifyAudioFacade.mocker.prepareForCallTo(
                                MockSpotifyAudioFacade.Method.togglePlay, returnValue: error)
                            
                            self.pressPlayPauseButton(spotifyPlaylistTableController)
                            
                            self.assertSimpleUIAlertControllerPresentedOnController(spotifyPlaylistTableController, withTitle: "Unable to Play Song", andMessage: error.localizedDescription)
                        }
                    }
                }
            }
            
            describe("press the song view button") {
                it("shows the spotify track view") {
                    self.pressSongViewButton(spotifyPlaylistTableController)
                    
                    expect(spotifyPlaylistTableController.presentedViewController).toEventually(
                        beAnInstanceOf(SpotifyTrackViewController))
                    let spotifyTrackViewController = spotifyPlaylistTableController.presentedViewController as? SpotifyTrackViewController
                    expect(spotifyTrackViewController?.spotifyAudioFacade as? MockSpotifyAudioFacade).to(beIdenticalTo(mockSpotifyAudioFacade))
                }
            }
            
            describe("playback status change") {
                context("when is playing") {
                    it("sets the play/pause button to the 'pause' system item") {
                        spotifyPlaylistTableController.changedPlaybackStatus(true)
                        
                        expect(self.getPlayPauseButtonSystemItemFromToolbar(spotifyPlaylistTableController)).to(equal(UIBarButtonSystemItem.Pause))
                    }
                }
                
                context("when is not playing") {
                    it("sets the play/pause button to the 'play' system item") {
                        spotifyPlaylistTableController.changedPlaybackStatus(false)
                        
                        expect(self.getPlayPauseButtonSystemItemFromToolbar(spotifyPlaylistTableController)).to(equal(UIBarButtonSystemItem.Play))
                    }
                }
            }
            
            describe("current track change") {
                beforeEach() {
                    mockControllerHelper.mocker.prepareForCallTo(MockControllerHelper.Method.getImageForURL, returnValue: image)
                }
                
                context("when the track is not nil") {
                    beforeEach() {
                        spotifyPlaylistTableController.changedCurrentTrack(spotifyTrack)
                    }
                    
                    it("updates the song view button image") {
                        expect(self.getSongViewButtonBackgroundImageFromToolbar(spotifyPlaylistTableController)).toEventually(equal(image))
                    }
                    
                    it("updates the selected song in the table") {
                        expect(spotifyPlaylistTableController.tableView.indexPathForSelectedRow?.row)
                            .toEventually(equal(1))
                    }
                }
                
                context("when the track is nil and previous track was not nil") {
                    beforeEach() {
                        spotifyPlaylistTableController.changedCurrentTrack(spotifyTrack)
                        
                        expect(self.getSongViewButtonBackgroundImageFromToolbar(spotifyPlaylistTableController)).toEventually(equal(image))
                        
                        spotifyPlaylistTableController.changedCurrentTrack(nil)
                    }
                    
                    it("removes the image from the song view button") {
                        expect(self.getSongViewButtonBackgroundImageFromToolbar(spotifyPlaylistTableController))
                            .toEventually(beNil())
                    }
                    
                    it("unselects all tracks in the table") {
                        expect(spotifyPlaylistTableController.tableView.indexPathForSelectedRow)
                            .toEventually(beNil())
                    }
                }
            }

            describe("playlist name pressed") {
                beforeEach() {
                    spotifyPlaylistTableController.playlistNameButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
                }
                
                afterEach() {
                    spotifyPlaylistTableController.presentedViewController?.removeFromParentViewController()
                }
                
                it("presents the playlist name entry view") {
                    expect(spotifyPlaylistTableController.presentedViewController).toEventually(beAnInstanceOf(PlaylistNameEntryController))
                }
                
                it("displays the current name in the playlist name entry view") {
                    let textField = (spotifyPlaylistTableController.presentedViewController as? PlaylistNameEntryController)?.textFields?.first
                    expect(textField?.text).to(equal(playlist.name))
                }
            }
            
            describe("new playlist pressed") {
                context("when the current playlist has been saved") {
                    beforeEach() {
                        mockSpotifyPlaylistService.mocker.prepareForCallTo(MockSpotifyPlaylistService.Method.savePlaylist, returnValue: SpotifyPlaylistService.PlaylistResult.Success(Playlist(name: "saved playlist", uri: NSURL(string: "uri"))))

                        self.pressSaveButton(spotifyPlaylistTableController)
                        self.advanceRunLoopForTimeInterval(0.0)
                        
                        expect(spotifyPlaylistTableController.saveButton.title).toEventually(equal("Playlist Saved"))
                    }
                    
                    it("unwinds to create playlist") {
                        self.pressNewPlaylistButton(spotifyPlaylistTableController)
                        self.advanceRunLoopForTimeInterval(0.0)
                        
                        expect(navigationController.topViewController)
                            .toEventually(beAnInstanceOf(CreatePlaylistController))
                    }
                }
                
                context("when the current playlist has not been saved") {
                    it("asks the user to confirm abandoning the playlist") {
                        self.pressNewPlaylistButton(spotifyPlaylistTableController)
                        self.advanceRunLoopForTimeInterval(0.0)
                        
                        self.assertSimpleUIAlertControllerPresentedOnController(spotifyPlaylistTableController, withTitle: "Unsaved Playlist", andMessage: "Abandon changes to this playlist?")
                    }
                }
            }
            
            describe("edit pressed") {
                context("switch to editing") {
                    it("updates the save button text") {
                        self.pressEditButton(spotifyPlaylistTableController)
                        
                        expect(spotifyPlaylistTableController.saveButton.title).to(equal("Editing Playlist"))
                    }
                    
                    it("disables the save button") {
                        spotifyPlaylistTableController.saveButton.enabled = true
                        
                        self.pressEditButton(spotifyPlaylistTableController)
                        
                        expect(spotifyPlaylistTableController.saveButton.enabled).toNot(beTrue())
                    }
                    
                    it("replaces the edit button with a done button") {
                        self.pressEditButton(spotifyPlaylistTableController)
                        
                        expect(spotifyPlaylistTableController.navigationItem.rightBarButtonItems?.first?
                            .title).to(equal("Done"))
                    }
                    
                    it("adds an 'add' button to the right bar button items") {
                        self.pressEditButton(spotifyPlaylistTableController)
                        
                        expect(spotifyPlaylistTableController.navigationItem.rightBarButtonItems?.count).to(equal(2))
                        expect((spotifyPlaylistTableController.navigationItem.rightBarButtonItems?.last)?
                            .valueForKey("systemItem") as? Int).to(equal(UIBarButtonSystemItem.Add.rawValue))
                        expect((spotifyPlaylistTableController.navigationItem.rightBarButtonItems?.last)?
                            .target as? UIViewController).to(beIdenticalTo(spotifyPlaylistTableController))
                        expect((spotifyPlaylistTableController.navigationItem.rightBarButtonItems?.last)?
                            .action).to(equal(Selector("addSong:")))
                    }
                }
                
                context("switch to not editing") {
                    beforeEach() {
                        self.pressEditButton(spotifyPlaylistTableController)
                    }
                    
                    it("updates the save button text") {
                        self.pressEditButton(spotifyPlaylistTableController)
                        
                        expect(spotifyPlaylistTableController.saveButton.title).to(equal("Save to Spotify"))
                    }
                    
                    it("enables the save button") {
                        spotifyPlaylistTableController.saveButton.enabled = false
                        
                        self.pressEditButton(spotifyPlaylistTableController)
                        
                        expect(spotifyPlaylistTableController.saveButton.enabled).to(beTrue())
                    }
                    
                    it("replaces the done button with the edit button") {
                        self.pressEditButton(spotifyPlaylistTableController)
                        
                        expect(spotifyPlaylistTableController.navigationItem.rightBarButtonItems?.first?
                            .title).to(equal("Edit"))
                    }
                    
                    it("removes the 'add' button from the right bar button items") {
                        self.pressEditButton(spotifyPlaylistTableController)
                        
                        expect(spotifyPlaylistTableController.navigationItem.rightBarButtonItems?.count).to(equal(1))
                    }
                }
                
                context("when play has already started") {
                    it("retains the selected song in the table") {
                        mockSpotifyAudioFacade.mocker.prepareForCallTo(MockSpotifyAudioFacade.Method.getCurrentSpotifyTrack, returnValue: spotifyTrack)
                        
                        self.pressEditButton(spotifyPlaylistTableController)

                        expect(spotifyPlaylistTableController.tableView.indexPathForSelectedRow?.row)
                            .toEventually(equal(1))
                    }
                }
            }
            
            describe("edit the table") {
                let firstIndexPath = NSIndexPath(forRow: 0, inSection: 0)
                let secondIndexPath = NSIndexPath(forRow: 1, inSection: 0)
                var deleteAction: UITableViewRowAction!
                var replaceAction: UITableViewRowAction!
                
                beforeEach() {
                    deleteAction = spotifyPlaylistTableController.tableView(spotifyPlaylistTableController.tableView, editActionsForRowAtIndexPath: firstIndexPath)![0]
                    replaceAction = spotifyPlaylistTableController.tableView(spotifyPlaylistTableController.tableView, editActionsForRowAtIndexPath: firstIndexPath)![1]
                    
                    self.pressEditButton(spotifyPlaylistTableController)
                }
                
                describe("reorder songs") {
                    context("when song position changes") {
                        it("updates the table to reflect the change") {
                            let firstCellTextPreEdit = spotifyPlaylistTableController.tableView(spotifyPlaylistTableController.tableView, cellForRowAtIndexPath: firstIndexPath).textLabel?.text
                            let secondCellTextPreEdit = spotifyPlaylistTableController.tableView(spotifyPlaylistTableController.tableView, cellForRowAtIndexPath: secondIndexPath).textLabel?.text

                            spotifyPlaylistTableController.tableView(spotifyPlaylistTableController.tableView, moveRowAtIndexPath: firstIndexPath, toIndexPath: secondIndexPath)
                            
                            let firstCellTextPostEdit = spotifyPlaylistTableController.tableView(spotifyPlaylistTableController.tableView, cellForRowAtIndexPath: firstIndexPath).textLabel?.text
                            let secondCellTextPostEdit = spotifyPlaylistTableController.tableView(spotifyPlaylistTableController.tableView, cellForRowAtIndexPath: secondIndexPath).textLabel?.text
                            expect(firstCellTextPostEdit).to(equal(secondCellTextPreEdit))
                            expect(firstCellTextPreEdit).to(equal(secondCellTextPostEdit))
                        }
                        
                        context("when play has not yet started") {
                            it("does not update the playlist with the spotify audio facade") {
                                spotifyPlaylistTableController.tableView(spotifyPlaylistTableController.tableView, moveRowAtIndexPath: firstIndexPath, toIndexPath: secondIndexPath)
                                self.advanceRunLoopForTimeInterval(0.05)
                                
                                expect(mockSpotifyAudioFacade.mocker.getCallCountFor(
                                    MockSpotifyAudioFacade.Method.updatePlaylist)).toEventually(equal(0))
                            }
                        }

                        context("when play has already started") {
                            let expectedNewIndex = 0
                            
                            beforeEach() {
                                mockSpotifyAudioFacade.mocker.prepareForCallTo(MockSpotifyAudioFacade.Method.getCurrentSpotifyTrack, returnValue: spotifyTrack)
                            }
                            
                            it("updates the selected song in the table") {
                                spotifyPlaylistTableController.tableView(spotifyPlaylistTableController.tableView, moveRowAtIndexPath: firstIndexPath, toIndexPath: secondIndexPath)
                                self.advanceRunLoopForTimeInterval(0.0)
                                
                                expect(spotifyPlaylistTableController.tableView.indexPathForSelectedRow?.row)
                                    .toEventually(equal(expectedNewIndex))
                            }
                            
                            it("updates the playlist with the spotify audio facade") {
                                spotifyPlaylistTableController.tableView(spotifyPlaylistTableController.tableView, moveRowAtIndexPath: firstIndexPath, toIndexPath: secondIndexPath)
                                self.advanceRunLoopForTimeInterval(0.0)
                                
                                self.verifyCallToUpdatePlaylistOn(mockSpotifyAudioFacade, expectedPlaylist: spotifyPlaylistTableController.playlist, expectedIndex: expectedNewIndex)
                            }
                        }
                    }
                }
                
                describe("delete song") {
                    it("removes the row from the table") {
                        spotifyPlaylistTableController.handleDeleteRow(deleteAction, indexPath: firstIndexPath)

                        expect(spotifyPlaylistTableController.tableView(spotifyPlaylistTableController.tableView, numberOfRowsInSection: 0)).to(equal(1))
                        expect(spotifyPlaylistTableController.tableView(spotifyPlaylistTableController.tableView, cellForRowAtIndexPath: firstIndexPath).textLabel?.text).to(equal(playlist.songs[1].title))
                    }
                    
                    context("when play has not yet started") {
                        it("does not update the playlist with the spotify audio facade") {
                            spotifyPlaylistTableController.handleDeleteRow(deleteAction, indexPath: firstIndexPath)
                            
                            expect(mockSpotifyAudioFacade.mocker.getCallCountFor(
                                MockSpotifyAudioFacade.Method.updatePlaylist)).toEventually(equal(0))
                        }
                    }
                    
                    context("when play has already started") {
                        let expectedNewIndex = 0
                        
                        beforeEach() {
                            mockSpotifyAudioFacade.mocker.prepareForCallTo(MockSpotifyAudioFacade.Method.getCurrentSpotifyTrack, returnValue: spotifyTrack)
                        }
                        
                        it("updates the selected song in the table") {
                            spotifyPlaylistTableController.handleDeleteRow(deleteAction, indexPath: firstIndexPath)
                            
                            expect(spotifyPlaylistTableController.tableView.indexPathForSelectedRow?.row)
                                .toEventually(equal(expectedNewIndex))
                        }
                        
                        it("updates the playlist with the spotify audio facade") {
                            spotifyPlaylistTableController.handleDeleteRow(deleteAction, indexPath: firstIndexPath)
                            
                            self.verifyCallToUpdatePlaylistOn(mockSpotifyAudioFacade, expectedPlaylist: spotifyPlaylistTableController.playlist, expectedIndex: expectedNewIndex)
                        }
                        
                        context("and the deleted song is playing") {
                            it("stops play") {
                                spotifyPlaylistTableController.handleDeleteRow(deleteAction, indexPath: secondIndexPath)
                                
                                expect(mockSpotifyAudioFacade.mocker.getCallCountFor(
                                    MockSpotifyAudioFacade.Method.stopPlay)).to(equal(1))
                            }
                        }
                    }
                }
                
                describe("replace song") {
                    it("sets the song replacement index") {
                        spotifyPlaylistTableController.handleReplaceRow(replaceAction, indexPath: firstIndexPath)

                        expect(spotifyPlaylistTableController.songReplacementIndexPath).to(equal(firstIndexPath))
                    }
                    
                    it("prompts to choose to use the same name") {
                        spotifyPlaylistTableController.handleReplaceRow(replaceAction, indexPath: firstIndexPath)
                        
                        self.assertSimpleUIAlertControllerPresentedOnController(spotifyPlaylistTableController, withTitle: "Replace this Song", andMessage: "(For Bobby McGee)")
                    }
                    
                    context("when the song is not associated with a contact") {
                        it("prompts the user to choose a new name") {
                            spotifyPlaylistTableController.handleReplaceRow(replaceAction, indexPath: secondIndexPath)
                            
                            expect(navigationController.topViewController)
                                .toEventually(beAnInstanceOf(SingleNameEntryController))
                        }
                    }
                }
                
                describe("add song") {
                    beforeEach() {
                        spotifyPlaylistTableController.songReplacementIndexPath = NSIndexPath()
                        spotifyPlaylistTableController.addSong(UIBarButtonItem())
                    }
                    
                    it("prompts the user to enter a name") {
                        expect(navigationController.topViewController)
                            .toEventually(beAnInstanceOf(SingleNameEntryController))
                    }
                    
                    it("nils the songReplacementIndexPath") {
                        expect(spotifyPlaylistTableController.songReplacementIndexPath).to(beNil())
                    }
                }
                
                describe("complete selection of song with contact") {
                    let newSong = Song(title: "Don’t call me Whitney, Bobby",
                        artistNames: ["Islands"],
                        uri: NSURL(string:"spotify:track:51L6XqGwYaRUh5qenzko3F")!)
                    var numberOfRowsBefore: Int!
                    
                    beforeEach() {
                        numberOfRowsBefore = spotifyPlaylistTableController.tableView(spotifyPlaylistTableController.tableView, numberOfRowsInSection: 0)
                    }
                    
                    context("when the songReplacementIndexPath is set") {
                        it("replaces the row in the table") {
                            spotifyPlaylistTableController.songReplacementIndexPath = firstIndexPath
                            
                            spotifyPlaylistTableController.completeSelectionOfSong(newSong, withContact: nil)
                            
                            expect(spotifyPlaylistTableController.tableView(spotifyPlaylistTableController.tableView, numberOfRowsInSection: 0)).to(equal(numberOfRowsBefore))
                            expect(spotifyPlaylistTableController.tableView(spotifyPlaylistTableController.tableView, cellForRowAtIndexPath: firstIndexPath).textLabel?.text).to(equal(newSong.title))
                            expect(spotifyPlaylistTableController.tableView(spotifyPlaylistTableController.tableView, cellForRowAtIndexPath: firstIndexPath).detailTextLabel?.text).to(equal(newSong.displayArtistName))
                        }
                    }
                    
                    context("when the songReplacementIndexPath is nil") {
                        it("appends the row to the end of the table") {
                            spotifyPlaylistTableController.songReplacementIndexPath = nil
                            
                            spotifyPlaylistTableController.completeSelectionOfSong(newSong, withContact: nil)

                            expect(spotifyPlaylistTableController.tableView(spotifyPlaylistTableController.tableView, numberOfRowsInSection: 0)).to(equal(numberOfRowsBefore + 1))
                            let newIndexPath = NSIndexPath(forRow: numberOfRowsBefore, inSection: 0)
                            expect(spotifyPlaylistTableController.tableView(spotifyPlaylistTableController.tableView, cellForRowAtIndexPath: newIndexPath).textLabel?.text).to(equal(newSong.title))
                            expect(spotifyPlaylistTableController.tableView(spotifyPlaylistTableController.tableView, cellForRowAtIndexPath: newIndexPath).detailTextLabel?.text).to(equal(newSong.displayArtistName))
                        }
                    }
                    
                    context("when play has not yet started") {
                        it("does not update the playlist with the spotify audio facade") {
                            spotifyPlaylistTableController.songReplacementIndexPath = firstIndexPath
                            spotifyPlaylistTableController.completeSelectionOfSong(newSong, withContact: nil)
                            
                            expect(mockSpotifyAudioFacade.mocker.getCallCountFor(
                                MockSpotifyAudioFacade.Method.updatePlaylist)).toEventually(equal(0))
                        }
                    }
                    
                    context("when play has already started") {
                        beforeEach() {
                            mockSpotifyAudioFacade.mocker.prepareForCallTo(MockSpotifyAudioFacade.Method.getCurrentSpotifyTrack, returnValue: spotifyTrack)
                        }
                        
                        context("and the replaced song is not currently playing") {
                            beforeEach() {
                                spotifyPlaylistTableController.songReplacementIndexPath = firstIndexPath
                                spotifyPlaylistTableController.completeSelectionOfSong(newSong, withContact: nil)
                            }
                            
                            it("updates the playlist with the spotify audio facade") {
                                self.verifyCallToUpdatePlaylistOn(mockSpotifyAudioFacade, expectedPlaylist: spotifyPlaylistTableController.playlist, expectedIndex: 1)
                            }
                            
                            it("does not restart play") {
                                expect(mockSpotifyAudioFacade.mocker.getCallCountFor(
                                    MockSpotifyAudioFacade.Method.playTracksForURIs)).to(equal(0))
                            }
                        }
                        
                        context("and the replaced song is playing") {
                            beforeEach() {
                                spotifyPlaylistTableController.songReplacementIndexPath = secondIndexPath
                                spotifyPlaylistTableController.completeSelectionOfSong(newSong, withContact: nil)
                            }
                            
                            it("does not update the playlist with the spotify audio facade") {
                                expect(mockSpotifyAudioFacade.mocker.getCallCountFor(
                                    MockSpotifyAudioFacade.Method.updatePlaylist)).to(equal(0))
                            }
                            
                            it("starts playing the new song") {
                                self.verifyCallsToPlayTracksForURIsOn(mockSpotifyAudioFacade, expectedURIs: spotifyPlaylistTableController.playlist.songURIs, expectedIndex: 1)
                            }
                        }
                    }
                }
                
                context("when editing complete") {
                    it("updates the save button text") {
                        self.pressEditButton(spotifyPlaylistTableController)
                        
                        expect(spotifyPlaylistTableController.saveButton.title).to(equal("Save to Spotify"))
                    }
                    
                    it("enables the save button") {
                        spotifyPlaylistTableController.saveButton.enabled = false
                        
                        self.pressEditButton(spotifyPlaylistTableController)
                        
                        expect(spotifyPlaylistTableController.saveButton.enabled).to(beTrue())
                    }
                    
                    context("and play has already started") {
                        beforeEach() {
                            mockSpotifyAudioFacade.mocker.prepareForCallTo(MockSpotifyAudioFacade.Method.getCurrentSpotifyTrack, returnValue: spotifyTrack)
                        }
                        
                        it("retains the selected song in the table") {
                            self.pressEditButton(spotifyPlaylistTableController)
                            
                            expect(spotifyPlaylistTableController.tableView.indexPathForSelectedRow?.row)
                                .toEventually(equal(1))
                        }
                        
                        context("and current track was deleted") {
                            it("unselects all tracks in the table") {
                                spotifyPlaylistTableController.handleDeleteRow(deleteAction, indexPath: secondIndexPath)

                                self.pressEditButton(spotifyPlaylistTableController)
                                self.advanceRunLoopForTimeInterval(0.05)

                                expect(spotifyPlaylistTableController.tableView.indexPathForSelectedRow)
                                    .toEventually(beNil())
                            }
                        }
                    }
                }
            }
            
            describe("unwind to create playlist") {
                it("stops play") {
                    spotifyPlaylistTableController.performSegueWithIdentifier(
                        "UnwindToCreatePlaylistFromPlaylistTableSegue", sender: nil)
                    self.advanceRunLoopForTimeInterval(0.0)
                    
                    expect(mockSpotifyAudioFacade.mocker.getCallCountFor(
                        MockSpotifyAudioFacade.Method.stopPlay)).to(equal(1))
                }
            }
            
            describe("segue to the SpotifySongSelectionController") {
                beforeEach() {
                    spotifyPlaylistTableController.songReplacementIndexPath = NSIndexPath(forRow: 0, inSection: 0)
                    spotifyPlaylistTableController.performSegueWithIdentifier("SelectSongSameContactSegue", sender: nil)
                }
                
                it("shows the spotify song selection table and sets the expected properties") {
                    expect(navigationController.topViewController)
                        .toEventually(beAnInstanceOf(SpotifySongSelectionTableController))
                    let spotifySongSelectionTableController = navigationController.topViewController as! SpotifySongSelectionTableController
                    expect(spotifySongSelectionTableController.searchContact).to(equal(playlist.songsWithContacts[0].contact))
                    expect(spotifySongSelectionTableController.songSelectionCompletionHandler).toNot(beNil())
                }
            }
            
            describe("segue to the SingleNameEntryController") {
                beforeEach() {
                    spotifyPlaylistTableController.songReplacementIndexPath = NSIndexPath(forRow: 0, inSection: 0)
                    spotifyPlaylistTableController.performSegueWithIdentifier("EnterNameSegue", sender: nil)
                }
                
                it("shows the single name entry view and sets the completion handler") {
                    expect(navigationController.topViewController)
                        .toEventually(beAnInstanceOf(SingleNameEntryController))
                    expect((navigationController.topViewController as? SingleNameEntryController)?.songSelectionCompletionHandler).toEventuallyNot(beNil())
                }
            }
        }
    }
    
    func pressSaveButton(spotifyPlaylistTableController: SpotifyPlaylistTableController) {
        pressBarButton(spotifyPlaylistTableController.saveButton)
    }
    
    func pressPlayPauseButton(spotifyPlaylistTableController: SpotifyPlaylistTableController) {
        pressBarButton(spotifyPlaylistTableController.playPauseButton)
    }
    
    func pressSongViewButton(spotifyPlaylistTableController: SpotifyPlaylistTableController) {
        pressBarButton(spotifyPlaylistTableController.songViewButton)
    }
    
    func pressNewPlaylistButton(spotifyPlaylistTableController: SpotifyPlaylistTableController) {
        pressBarButton(spotifyPlaylistTableController.newPlaylistButton)
    }
    
    func pressEditButton(spotifyPlaylistTableController: SpotifyPlaylistTableController) {
        pressBarButton(spotifyPlaylistTableController.editButtonItem())
    }
    
    func pressBarButton(barButton: UIBarButtonItem) {
        UIApplication.sharedApplication().sendAction(barButton.action, to: barButton.target, from: self, forEvent: nil)
    }
    
    func assertSimpleUIAlertControllerPresentedOnController(parentController: UIViewController, withTitle expectedTitle: String, andMessage expectedMessage: String) {
        self.advanceRunLoopForTimeInterval(0.5)
        expect(parentController.presentedViewController).toEventuallyNot(beNil())
        expect(parentController.presentedViewController).toEventually(beAnInstanceOf(UIAlertController))
        if let alertController = parentController.presentedViewController as? UIAlertController {
            expect(alertController.title).toEventually(equal(expectedTitle))
            expect(alertController.message).toEventually(equal(expectedMessage))
        }
    }
    
    func getPlayPauseButtonSystemItemFromToolbar(spotifyPlaylistTableController: SpotifyPlaylistTableController) -> UIBarButtonSystemItem {
        let playPauseButton = spotifyPlaylistTableController.toolbarItems?[5]
        return UIBarButtonSystemItem(rawValue: playPauseButton!.valueForKey("systemItem") as! Int)!
    }
    
    func getSongViewButtonBackgroundImageFromToolbar(spotifyPlaylistTableController: SpotifyPlaylistTableController) -> UIImage? {
        let songViewButton = spotifyPlaylistTableController.toolbarItems?[0]
        return (songViewButton?.customView as? UIButton)?.currentBackgroundImage
    }
    
    func verifyCallsToPlayTracksForURIsOn(mockSpotifyAudioFacade: MockSpotifyAudioFacade, expectedURIs: [NSURL], expectedIndex: Int) {
        expect(mockSpotifyAudioFacade.mocker.getNthCallTo(MockSpotifyAudioFacade.Method.playTracksForURIs, n: 0)?[0] as? [NSURL]).toEventually(equal(expectedURIs))
        expect(mockSpotifyAudioFacade.mocker.getNthCallTo(MockSpotifyAudioFacade.Method.playTracksForURIs, n: 0)?[1] as? Int).toEventually(equal(expectedIndex))
    }
    
    func verifyCallToUpdatePlaylistOn(mockSpotifyAudioFacade: MockSpotifyAudioFacade, expectedPlaylist: Playlist, expectedIndex: Int) {
        self.advanceRunLoopForTimeInterval(0.1)
        expect(mockSpotifyAudioFacade.mocker.getNthCallTo(MockSpotifyAudioFacade.Method.updatePlaylist, n: 0)?[0] as? Playlist).toEventually(equal(expectedPlaylist))
        expect(mockSpotifyAudioFacade.mocker.getNthCallTo(MockSpotifyAudioFacade.Method.updatePlaylist, n: 0)?[1] as? Int).toEventually(equal(expectedIndex))
    }
    
    func advanceRunLoopForTimeInterval(timeInterval: Double) {
        NSRunLoop.mainRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: timeInterval))
    }
}

class MockSpotifyPlaylistService: SpotifyPlaylistService {
    
    let mocker = Mocker()
    
    struct Method {
        static let savePlaylist = "savePlaylist"
    }
    
    override func savePlaylist(playlist: Playlist!, callback: (SpotifyPlaylistService.PlaylistResult) -> Void) {
        mocker.recordCall(Method.savePlaylist, parameters: playlist)
        let mockedResult = mocker.returnValueForCallTo(Method.savePlaylist)
        if let mockedResult = mockedResult as? SpotifyPlaylistService.PlaylistResult {
            callback(mockedResult)
        } else {
            callback(.Success(Playlist(name: "unimportant mocked playlist")))
        }
    }
}
