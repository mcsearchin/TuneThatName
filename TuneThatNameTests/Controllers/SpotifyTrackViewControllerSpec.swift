import TuneThatName
import Quick
import Nimble

class SpotifyTrackViewControllerSpec: QuickSpec {
    
    override func spec() {
        describe("SpotifyTrackViewController") {
            let spotifyTrack = SpotifyTrack(
                uri: NSURL(string: "spotify:track:1TYlZJWUNAJFXeF8FbPRIp")!,
                name: "Springfield, Or Bobby Got A Shadfly Caught In His Hair",
                artistNames: ["Sufjan Stevens"],
                albumName: "The Avalanche",
                albumLargestCoverImageURL: NSURL(string: "https://i.scdn.co/image/eecb04997c5c163e2fc73804cc169fa46e87666e")!,
                albumSmallestCoverImageURL: NSURL(string: "https://i.scdn.co/image/9fc8918a40a16e51eab4dd97512d623c2b590c63")!)
            let image = UIImage(named: "yuck.png", inBundle: NSBundle(forClass: SpotifyPlaylistTableControllerSpec.self), compatibleWithTraitCollection: nil)
            
            let playbackError = NSError(domain: "domain", code: 999, userInfo: [NSLocalizedDescriptionKey: "YOU CAN'T CONTROL ME!"])
            let expectedErrorTitle = "Unable to Control Playback"
            
            var spotifyTrackViewController: SpotifyTrackViewController!
            var mockSpotifyAudioFacade: MockSpotifyAudioFacade!
            var mockControllerHelper: MockControllerHelper!
            
            describe("presenting/using controller") {
                
                beforeEach() {
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    
                    spotifyTrackViewController = storyboard.instantiateViewControllerWithIdentifier("SpotifyTrackViewController") as! SpotifyTrackViewController
                    
                    mockSpotifyAudioFacade = MockSpotifyAudioFacade()
                    spotifyTrackViewController.spotifyAudioFacade = mockSpotifyAudioFacade
                    mockControllerHelper = MockControllerHelper()
                    spotifyTrackViewController.controllerHelper = mockControllerHelper
                    
                    UIApplication.sharedApplication().keyWindow!.rootViewController = spotifyTrackViewController
                }
                
                it("sets itself as the playback delegate on the spotifyAudioFacade") {
                    expect(mockSpotifyAudioFacade.mocker.getNthCallTo(MockSpotifyAudioFacade.Method.setPlaybackDelegate, n: 0)?.first as? SpotifyTrackViewController).to(beIdenticalTo(spotifyTrackViewController))
                }
                
                describe("current track change") {
                    let newSpotifyTrack = SpotifyTrack(
                        uri: NSURL(string: "spotify:track:453d5sjBIPAfhajumXOPIs")!,
                        name: "Thunderclap For Bobby Pyn",
                        artistNames: ["Sonic Youth"],
                        albumName: "The Eternal",
                        albumLargestCoverImageURL: NSURL(string: "https://i.scdn.co/image/69f66e5ed0071a7c09705145e5bc7baf8a389499")!,
                        albumSmallestCoverImageURL: NSURL(string: "https://i.scdn.co/image/8775b33d7423ca4281f1be7477f5a7e1ca3ce588")!)
                    let otherImage = UIImage(named: "skull.png", inBundle: NSBundle(forClass: SpotifyPlaylistTableControllerSpec.self), compatibleWithTraitCollection: nil)
                    
                    beforeEach() {
                        // this first call will happen when the view appears
                        mockSpotifyAudioFacade.mocker.prepareForCallTo(MockSpotifyAudioFacade.Method.getCurrentSpotifyTrack, returnValue: spotifyTrack)
                        mockControllerHelper.mocker.prepareForCallTo(MockControllerHelper.Method.getImageForURL, returnValue: image)
                        spotifyTrackViewController.changedCurrentTrack(spotifyTrack)
                        
                        mockControllerHelper.mocker.prepareForCallTo(MockControllerHelper.Method.getImageForURL, returnValue: otherImage)
                    }
                    
                    it("updates the title, artist, and album label text for the spotify track") {
                        spotifyTrackViewController.changedCurrentTrack(newSpotifyTrack)
                        
                        self.assertCorrectLabelTextOnSpotifyTrackViewController(spotifyTrackViewController, forSpotifyTrack: newSpotifyTrack)
                    }
                    
                    context("when the track is current in the audio facade") {
                        it("updates the album cover image for the spotify track") {
                            mockSpotifyAudioFacade.mocker.prepareForCallTo(MockSpotifyAudioFacade.Method.getCurrentSpotifyTrack, returnValue: newSpotifyTrack)
                            
                            spotifyTrackViewController.changedCurrentTrack(newSpotifyTrack)
                            
                            expect(spotifyTrackViewController.albumImageView.image).toEventually(equal(otherImage))
                        }
                    }
                    
                    context("when the track is no longer current in the audio facade") {
                        it("does not update the album cover image for the spotify track") {
                            spotifyTrackViewController.changedCurrentTrack(newSpotifyTrack)
                            
                            expect(spotifyTrackViewController.albumImageView.image).toEventually(equal(image))
                        }
                    }
                }
                
                describe("playback status change") {
                    beforeEach() {
                        // this first call will happen when the view appears
                        mockSpotifyAudioFacade.mocker.prepareForCallTo(MockSpotifyAudioFacade.Method.getIsPlaying, returnValue: true)
                        spotifyTrackViewController.changedPlaybackStatus(true)
                    }
                    
                    context("when is playing") {
                        it("sets the play/pause button to the 'pause' system item") {
                            spotifyTrackViewController.changedPlaybackStatus(true)
                            
                            expect(self.getPlayPauseButtonSystemItemFromToolbar(spotifyTrackViewController)).to(equal(UIBarButtonSystemItem.Pause))
                        }
                    }
                    
                    context("when is not playing") {
                        it("sets the play/pause button to the 'play' system item") {
                            spotifyTrackViewController.changedPlaybackStatus(false)
                            
                            expect(self.getPlayPauseButtonSystemItemFromToolbar(spotifyTrackViewController)).to(equal(UIBarButtonSystemItem.Play))
                        }
                    }
                }
                
                describe("press the play/pause button") {
                    it("toggles play") {
                        self.pressPlayPauseButton(spotifyTrackViewController)
                        
                        expect(mockSpotifyAudioFacade.mocker.getCallCountFor(
                            MockSpotifyAudioFacade.Method.togglePlay)).toEventually(equal(1))
                    }
                    
                    context("and the spotify audio facade calls back with an error") {
                        it("displays the error message in an alert") {
                            mockSpotifyAudioFacade.mocker.prepareForCallTo(MockSpotifyAudioFacade.Method.togglePlay, returnValue: playbackError)
                            
                            self.pressPlayPauseButton(spotifyTrackViewController)
                            
                            self.assertSimpleUIAlertControllerPresentedOnController(spotifyTrackViewController, withTitle: expectedErrorTitle, andMessage: playbackError.localizedDescription)
                        }
                    }
                }
                
                describe("press the next track button") {
                    it("skips to next track") {
                        self.pressNextTrackButton(spotifyTrackViewController)
                        
                        expect(mockSpotifyAudioFacade.mocker.getCallCountFor(
                            MockSpotifyAudioFacade.Method.toNextTrack)).to(equal(1))
                    }
                    
                    context("and the spotify audio facade calls back with an error") {
                        it("displays the error message in an alert") {
                            mockSpotifyAudioFacade.mocker.prepareForCallTo(MockSpotifyAudioFacade.Method.toNextTrack, returnValue: playbackError)
                            
                            self.pressNextTrackButton(spotifyTrackViewController)
                            
                            self.assertSimpleUIAlertControllerPresentedOnController(spotifyTrackViewController, withTitle: expectedErrorTitle, andMessage: playbackError.localizedDescription)
                        }
                    }
                }
                
                describe("press the previous track button") {
                    it("skips to previous track") {
                        self.pressPreviousTrackButton(spotifyTrackViewController)
                        
                        expect(mockSpotifyAudioFacade.mocker.getCallCountFor(
                            MockSpotifyAudioFacade.Method.toPreviousTrack)).to(equal(1))
                    }
                    
                    context("and the spotify audio facade calls back with an error") {
                        it("displays the error message in an alert") {
                            mockSpotifyAudioFacade.mocker.prepareForCallTo(MockSpotifyAudioFacade.Method.toPreviousTrack, returnValue: playbackError)
                            
                            self.pressPreviousTrackButton(spotifyTrackViewController)
                            
                            self.assertSimpleUIAlertControllerPresentedOnController(spotifyTrackViewController, withTitle: expectedErrorTitle, andMessage: playbackError.localizedDescription)

                            spotifyTrackViewController.dismissViewControllerAnimated(false, completion: nil)
                        }
                    }
                }
            }
            
            describe("next/previous track buttons") {
                beforeEach() {
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    spotifyTrackViewController = storyboard.instantiateViewControllerWithIdentifier("SpotifyTrackViewController") as! SpotifyTrackViewController
                    spotifyTrackViewController.spotifyAudioFacade = MockSpotifyAudioFacade()
                }
                
                context("hidden") {
                    it("removes buttons from toolbar") {
                        spotifyTrackViewController.hidePreviousAndNextTrackButtons = true
                        UIApplication.sharedApplication().keyWindow!.rootViewController = spotifyTrackViewController
                        
                        expect(spotifyTrackViewController.toolbar.items?.count).to(equal(5))
                    }
                }
                
                context("not hidden") {
                    it("leaves buttons on toolbar") {
                        spotifyTrackViewController.hidePreviousAndNextTrackButtons = false
                        UIApplication.sharedApplication().keyWindow!.rootViewController = spotifyTrackViewController
                        
                        expect(spotifyTrackViewController.toolbar.items?.count).to(equal(7))
                    }
                }
            }
            
            describe("close pressed") {
                it("dismisses controller returning to parent controller") {
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    spotifyTrackViewController = storyboard.instantiateViewControllerWithIdentifier("SpotifyTrackViewController") as!  SpotifyTrackViewController
                    mockSpotifyAudioFacade = MockSpotifyAudioFacade()
                    spotifyTrackViewController.spotifyAudioFacade = MockSpotifyAudioFacade()
                    let presentingViewController = UIApplication.sharedApplication().keyWindow!.rootViewController!
                    presentingViewController.presentViewController(spotifyTrackViewController, animated: false, completion: nil)
                    NSRunLoop.mainRunLoop().runUntilDate(NSDate(timeIntervalSinceNow: 0.5))
                    
                    self.pressClosedButton(spotifyTrackViewController)
                    
                    expect(presentingViewController.presentedViewController).toEventually(beNil())
                }
            }
        }
    }
    
    func pressPlayPauseButton(spotifyTrackViewController: SpotifyTrackViewController) {
        pressBarButtonItem(spotifyTrackViewController.toolbar.items![6])
    }
    
    func pressNextTrackButton(spotifyTrackViewController: SpotifyTrackViewController) {
        pressBarButtonItem(spotifyTrackViewController.toolbar.items![4])
    }
    
    func pressPreviousTrackButton(spotifyTrackViewController: SpotifyTrackViewController) {
        pressBarButtonItem(spotifyTrackViewController.toolbar.items![2])
    }
    
    func pressClosedButton(spotifyTrackViewController: SpotifyTrackViewController) {
        pressBarButtonItem(spotifyTrackViewController.toolbar.items![0])
    }
    
    func pressBarButtonItem(barButtonItem: UIBarButtonItem) {
        UIApplication.sharedApplication().sendAction(barButtonItem.action, to: barButtonItem.target, from: self, forEvent: nil)
    }
    
    func assertCorrectLabelTextOnSpotifyTrackViewController(spotifyTrackViewController: SpotifyTrackViewController, forSpotifyTrack spotifyTrack: SpotifyTrack) {
        expect(spotifyTrackViewController.titleLabel.text).to(equal(spotifyTrack.name))
        expect(spotifyTrackViewController.artistLabel.text).to(equal(spotifyTrack.displayArtistName))
        expect(spotifyTrackViewController.albumLabel.text).to(equal(spotifyTrack.albumName))
    }
    
    func getPlayPauseButtonSystemItemFromToolbar(spotifyTrackViewController: SpotifyTrackViewController) -> UIBarButtonSystemItem {
        let playPauseButton = spotifyTrackViewController.toolbar.items?[6]
        return UIBarButtonSystemItem(rawValue: playPauseButton!.valueForKey("systemItem") as! Int)!
    }
    
    func assertSimpleUIAlertControllerPresentedOnController(parentController: UIViewController, withTitle expectedTitle: String, andMessage expectedMessage: String) {
        expect(parentController.presentedViewController).toEventuallyNot(beNil())
        expect(parentController.presentedViewController).toEventually(beAnInstanceOf(UIAlertController))
        if let alertController = parentController.presentedViewController as? UIAlertController {
            expect(alertController.title).toEventually(equal(expectedTitle))
            expect(alertController.message).toEventually(equal(expectedMessage))
        }
    }
}
