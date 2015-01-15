/*
 * Copyright (c) 2010, Dominic DiMarco (dominic@ReallyLongAddress.com)
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * -Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 * 
 * -Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 * 
 * -Neither the name of the author nor the
 * names of its contributors may be used to endorse or promote products
 * derived from this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
 */

//
//  FbGraph.m
//  oAuth2Test
//
//  Created by dominic dimarco (ddimarco@room214.com @dominicdimarco) on 5/23/10.
//


#import "FbGraph.h"
#import "SBJSON.h"
#import "FbGraphFile.h"
#import <QuartzCore/QuartzCore.h>
#import "Toast.h"
#import "MyDevice.h"

#define	CLOSE_BUTTON_WIDTH		24
#define	CLOSE_BUTTON_HEIGHT		24

@implementation FbGraph

@synthesize facebookClientID;
@synthesize redirectUri;
@synthesize accessToken;
@synthesize webView;

@synthesize callbackObject;
@synthesize callbackSelector;


- (id)initWithFrame:(CGRect)frame {
    
    //self.view.frame = super.view.frame;// initWithFrame:frame];
    if (self) {
        // Initialization code.
		//self.view.backgroundColor = [UIColor colorWithRed:23.1/255.0 green:34.9/255.0 blue:59.6/255 alpha:1.0f];
    }
    return self;
}

-(void)setProperty:(NSString*)fbcid
{
	self.facebookClientID = fbcid;
	self.redirectUri = @"http://www.facebook.com/connect/login_success.html";	
}

- (void)presentFromController:(UIViewController*)controller {
	
	UINavigationController* navController = [[[UINavigationController alloc] initWithRootViewController:self] autorelease];
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(closeMe:)];
    navController.navigationBar.tintColor = APP_THEME_COLOR;
	[controller presentModalViewController:navController animated:YES];
}

- (void)authenticateUserWithCallbackObject:(id)anObject andSelector:(SEL)selector andExtendedPermissions:(NSString *)extended_permissions andSuperView:(UIViewController *)super_view
{
	parentController = super_view;
	self.callbackObject = anObject;
	self.callbackSelector = selector;
	
	NSString *url_string = [NSString stringWithFormat:@"https://graph.facebook.com/oauth/authorize?client_id=%@&redirect_uri=%@&scope=%@&type=user_agent&display=touch", facebookClientID, redirectUri, extended_permissions];
	NSURL *url = [NSURL URLWithString:url_string];
	NSURLRequest *request = [NSURLRequest requestWithURL:url];
	
	
	//[super_view.view addSubview:self.view];
	
	self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 
															   0, 
															   parentController.view.frame.size.width, 
															   parentController.view.frame.size.height)];

	//aWebView.hidden = TRUE;
	self.webView.delegate = self;
	
	//self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
	[self.view addSubview:self.webView];
	
	//self.webView.hidden = YES;
	[webView loadRequest:request];
	
	_spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:
				 UIActivityIndicatorViewStyleWhite];
	_spinner.center = CGPointMake(self.webView.bounds.size.width / 2,self.webView.bounds.size.height / 2);
	_spinner.autoresizingMask =
	UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin
	| UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
	[_spinner startAnimating];
	//[self.view addSubview:_spinner];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:_spinner] autorelease];
	
	//[self presentFromController:parentController];
	
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	[_spinner startAnimating];
	_spinner.hidden = NO;
	return TRUE;
}

-(void)stopIfWebViewLoading
{
	[self.webView stopLoading];
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

-(void)closeMe:(id)sender
{
	[self stopIfWebViewLoading];
	[self dismissModalViewControllerAnimated:YES];
	
	for (UIView *subView in [parentController.view subviews]) {
		if ([subView isKindOfClass:[Toast class]]) {
			[subView removeFromSuperview];
		}
	}
}

- (FbGraphResponse *)doGraphGet:(NSString *)action withGetVars:(NSDictionary *)get_vars {
	
	NSString *url_string = [NSString stringWithFormat:@"https://graph.facebook.com/%@?", action];
	
	//tack on any get vars we have...
	if ( (get_vars != nil) && ([get_vars count] > 0) ) {
		
		NSEnumerator *enumerator = [get_vars keyEnumerator];
		NSString *key;
		NSString *value;
		while ((key = (NSString *)[enumerator nextObject])) {
			value = (NSString *)[get_vars objectForKey:key];
			url_string = [NSString stringWithFormat:@"%@%@=%@&", url_string, key, value];
		}//end while	
	}//end if
	
	if (accessToken != nil) {
		//now that any variables have been appended, let's attach the access token....
		url_string = [NSString stringWithFormat:@"%@access_token=%@", url_string, self.accessToken];
	}
	
	//encode the string
	url_string = [url_string stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	
	return [self doGraphGetWithUrlString:url_string];
}

- (FbGraphResponse *)doGraphGetWithUrlString:(NSString *)url_string {
	
	FbGraphResponse *return_value = [[[FbGraphResponse alloc] init] autorelease];
	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url_string]];
	
	NSError *err;
	NSURLResponse *resp;
	NSData *response = [NSURLConnection sendSynchronousRequest:request returningResponse:&resp error:&err];
	
	if (resp != nil) {
		
		/**
		 * In the case we request a picture (avatar) the Graph API will return to us the actual image
		 * bits versus a url to the image.....
		 **/
		if ([resp.MIMEType isEqualToString:@"image/jpeg"]) {
			
			UIImage *image = [UIImage imageWithData:response];
			return_value.imageResponse = image;
			
		} else {
		    
			NSString *stringResponse = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
			return_value.htmlResponse = stringResponse;
			[stringResponse release];			
		}
		
	} else if (err != nil) {
		return_value.error = err;
	}
	
	return return_value;
	
}

- (FbGraphResponse *)doGraphPost:(NSString *)action withPostVars:(NSDictionary *)post_vars 
{
	FbGraphResponse *return_value = [[[FbGraphResponse alloc] init] autorelease];
	
	NSString *urlString = [NSString stringWithFormat:@"https://graph.facebook.com/%@", action];
	
	NSURL *url = [NSURL URLWithString:urlString];
	NSString *boundary = @"----1010101010";
	NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
	[request setHTTPMethod:@"POST"];
	[request addValue:contentType forHTTPHeaderField: @"Content-Type"];
	
	NSMutableData *body = [NSMutableData data];
	[body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	NSEnumerator *enumerator = [post_vars keyEnumerator];
	NSString *key;
	NSString *value;
	NSString *content_disposition;
	
	//loop through all our parameters 
	while ((key = (NSString *)[enumerator nextObject])) {
		
		//if it's a picture (file)...we have to append the binary data
		if ([key isEqualToString:@"file"]) {
//			NSLog(@"fbGraph doGraphPost started...6");	
			/*
			 * the FbGraphFile object is smart enough to append it's data to 
			 * the request automagically, regardless of the type of file being
			 * attached
			 */
			FbGraphFile *upload_file = (FbGraphFile *)[post_vars objectForKey:key];
			[upload_file appendDataToBody:body];
			
			//key/value nsstring/nsstring
		} else {
//			NSLog(@"fbGraph doGraphPost started...7");	
			value = (NSString *)[post_vars objectForKey:key];
			
			content_disposition = [NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key];
			[body appendData:[content_disposition dataUsingEncoding:NSUTF8StringEncoding]];
			[body appendData:[value dataUsingEncoding:NSUTF8StringEncoding]];
			
		}//end else
		
//		NSLog(@"fbGraph doGraphPost started...8");	
		[body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		
	}//end while
	
	//add our access token
	[body appendData:[@"Content-Disposition: form-data; name=\"access_token\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[accessToken dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	[request setHTTPBody:body];
	[request addValue:[NSString stringWithFormat:@"%d", body.length] forHTTPHeaderField: @"Content-Length"];
	
	//quite a few lines of code to simply do the business of the HTTP connection....
    NSURLResponse *response;
    NSData *data_reply;
	NSError *err;
	
    data_reply = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&err];
	
	NSString *stringResponse = [[NSString alloc] initWithData:data_reply encoding:NSUTF8StringEncoding];
    return_value.htmlResponse = stringResponse;
	[stringResponse release];
	
	return return_value;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	
	return ((interfaceOrientation == UIDeviceOrientationLandscapeRight) || (interfaceOrientation == UIDeviceOrientationLandscapeLeft));
}

#pragma mark -
#pragma mark UIWebViewDelegate Function
- (void)webViewDidFinishLoad:(UIWebView *)_webView {
	
	//NSLog(@"Start loading finished...");
	
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	
	[_spinner stopAnimating];
	_spinner.hidden = YES;
	//[self.navigationItem.rightBarButtonItem stopAnimating];
//	self.webView.hidden = NO;
	/**
	 * Since there's some server side redirecting involved, this method/function will be called several times
	 * we're only interested when we see a url like:  http://www.facebook.com/connect/login_success.html#access_token=..........
	 */
	
	//get the url string
	NSString *url_string = [((_webView.request).URL) absoluteString];
	
	//looking for "access_token="
	NSRange access_token_range = [url_string rangeOfString:@"access_token="];
	
	//looking for "error_reason=user_denied"
	NSRange cancel_range = [url_string rangeOfString:@"error_reason=user_denied"];
	
	//self.webView.hidden = FALSE;	//war
	
	//it exists?  coolio, we have a token, now let's parse it out....
	if (access_token_range.length > 0) {		
		//we want everything after the 'access_token=' thus the position where it starts + it's length
		int from_index = access_token_range.location + access_token_range.length;
		NSString *access_token = [url_string substringFromIndex:from_index];
		
		//finally we have to url decode the access token
		access_token = [access_token stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		
		//remove everything '&' (inclusive) onward...
		NSRange period_range = [access_token rangeOfString:@"&"];
		
		//move beyond the .
		access_token = [access_token substringToIndex:period_range.location];
		
		//store our request token....
		self.accessToken = access_token;
		
		//[self.view removeFromSuperview];
		[self dismissModalViewControllerAnimated:NO];
		
		//tell our callback function that we're done logging in :)
		if ( (callbackObject != nil) && (callbackSelector != nil) ) {
			[callbackObject performSelector:callbackSelector];
		}
		
		//the user pressed cancel
	} else if (cancel_range.length > 0) {
		
		//[self.view removeFromSuperview];
		[self dismissModalViewControllerAnimated:NO];
		
		//tell our callback function that we're done logging in :)
		if ( (callbackObject != nil) && (callbackSelector != nil) ) {
			[callbackObject performSelector:callbackSelector];
		}		
	}else {
		[self performSelector:@selector(showAfterDelay) withObject:nil afterDelay:1.0];
	}

}

- (void)showAfterDelay
{
	//self.webView.hidden = FALSE; 
	[self presentFromController:parentController];
}

-(void) dealloc {
	
	[facebookClientID release];
	[redirectUri release];
	[accessToken release];
	[webView release];
    [super dealloc];
}

@end