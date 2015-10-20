import TuneThatName
import Quick
import Nimble

class SpotifyAuthServicesSpec: QuickSpec {
    
    var callbackSession: SPTSession?
    var callbackError: NSError?
    
    func doWithSessionCallback(authResult: SpotifyAuthService.AuthResult) {
        switch (authResult) {
        case .Success(let session):
            self.callbackSession = session
        case .Failure(let error):
            self.callbackError = error
        }
    }
    
    override func spec() {
        describe("The Spotify Auth Service") {
            var spotifyAuthService: SpotifyAuthService!
            var mockSPTAuth: MockSPTAuth!
            
            beforeEach() {
                self.callbackSession = nil
                self.callbackError = nil

                mockSPTAuth = MockSPTAuth()
                spotifyAuthService = SpotifyAuthService(spotifyAuth: mockSPTAuth)
            }
            
            describe("do with session") {
                context("when the session is valid") {
                    let session = self.getSPTSessionThatExpiresIn(60)
                    
                    it("calls back with the session") {
                        mockSPTAuth.mocker.prepareForCallTo(MockSPTAuth.Method.getSession, returnValue: session)
                        
                        spotifyAuthService.doWithSession(self.doWithSessionCallback)
                        
                        expect(self.callbackSession).to(equal(session))
                        expect(self.callbackError).to(beNil())
                    }
                }
                
                context("when the session is invalid") {
                    let session = self.getSPTSessionThatExpiresIn(-60)
                    
                    beforeEach() {
                        mockSPTAuth.mocker.prepareForCallTo(MockSPTAuth.Method.getSession, returnValue: session)
                    }
                    
                    context("and the auth has a refresh service") {
                        beforeEach() {
                            mockSPTAuth.mocker.prepareForCallTo(MockSPTAuth.Method.hasTokenRefreshService, returnValue: true)
                        }
                        
                        it("it tries to renew the session") {
                            spotifyAuthService.doWithSession(self.doWithSessionCallback)
                            
                            expect(mockSPTAuth.mocker.getCallCountFor(MockSPTAuth.Method.renewSession)).toEventually(equal(1))
                        }
                        
                        context("and session renewal succeeds") {
                            let newSession = self.getSPTSessionThatExpiresIn(60)
                            
                            it("calls back with the new session") {
                                mockSPTAuth.mocker.prepareForCallTo(MockSPTAuth.Method.renewSession, returnValue: newSession)
                                
                                spotifyAuthService.doWithSession(self.doWithSessionCallback)
                                
                                expect(mockSPTAuth.mocker.getNthCallTo(MockSPTAuth.Method.setSession, n: 0)?.first as? SPTSession).toEventually(equal(newSession))
                                expect(self.callbackSession).toEventually(equal(newSession))
                                expect(self.callbackError).to(beNil())
                            }
                        }
                        
                        context("and session renewal does not call back with a new session") {
                            it("opens the login view") {
                                mockSPTAuth.mocker.prepareForCallTo(MockSPTAuth.Method.renewSession, returnValue: nil)
                                
                                spotifyAuthService.doWithSession(self.doWithSessionCallback)
                                
                                self.assertSPTAuthViewPresented()
                            }
                        }
                    }
                    
                    context("and the auth does not have a refresh service") {
                        beforeEach() {
                            mockSPTAuth.mocker.prepareForCallTo(MockSPTAuth.Method.hasTokenRefreshService, returnValue: false)
                        }
                        
                        it("opens the login view") {
                            spotifyAuthService.doWithSession(self.doWithSessionCallback)
                            
                            self.assertSPTAuthViewPresented()
                        }

                        context("and the login succeeds") {
                            let sessionAfterLogin = self.getSPTSessionThatExpiresIn(3600)
                            
                            it("calls back with the new session") {
                                spotifyAuthService.doWithSession(self.doWithSessionCallback)
                                let sptAuthViewController = self.assertSPTAuthViewPresented()
                                
                                if let sptAuthViewController = sptAuthViewController {
                                    spotifyAuthService.authenticationViewController(sptAuthViewController, didLoginWithSession: sessionAfterLogin)
                                    
                                    expect(self.callbackSession).toEventually(equal(sessionAfterLogin))
                                    expect(self.callbackError).to(beNil())
                                }
                            }
                        }
                        
                        context("and the login fails") {
                            let error = NSError(domain: "com.spotify.ios", code: 3487634, userInfo: [NSLocalizedDescriptionKey: "error logging in"])

                            it("calls back with the error") {
                                spotifyAuthService.doWithSession(self.doWithSessionCallback)
                                let sptAuthViewController = self.assertSPTAuthViewPresented()
                                
                                if let sptAuthViewController = sptAuthViewController {
                                    spotifyAuthService.authenticationViewController(sptAuthViewController, didFailToLogin: error)
                                    
                                    expect(self.callbackError).toEventually(equal(error))
                                    expect(self.callbackSession).to(beNil())
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func getSPTSessionThatExpiresIn(expiresIn: NSTimeInterval) -> SPTSession {
        return SPTSession(userName: "user", accessToken: "token", expirationDate: NSDate(timeIntervalSinceNow: expiresIn))
    }
    
    func assertSPTAuthViewPresented() -> SPTAuthViewController? {
        let navigationControler = UIApplication.sharedApplication().delegate!.window!!.rootViewController! as! UINavigationController
        expect(navigationControler.topViewController!.presentedViewController)
            .toEventually(beAnInstanceOf(SPTAuthViewController))
        return navigationControler.topViewController!.presentedViewController as? SPTAuthViewController
    }
}