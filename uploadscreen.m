#import <Cocoa/Cocoa.h>
int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	
	if ( argc != 2 ) /* argc should be 2 for correct execution */
    {
        /* We print argv[0] assuming it is the program name */
        printf( "usage: %s appname \n", argv[0] );
		return 0;
    }
	
	NSString *stringFromArgv = [NSString stringWithCString:argv[1] encoding:NSUTF8StringEncoding]; 
	
	NSArray *windowList = (NSArray*)CGWindowListCopyWindowInfo(kCGWindowListOptionAll | kCGWindowListOptionOnScreenOnly, kCGNullWindowID);
	NSData* data = [NSData data];
	
	BOOL found = NO;
	
	for (NSDictionary *entry in windowList) {
		// The flags that we pass to CGWindowListCopyWindowInfo will automatically filter out most undesirable windows.
		// However, it is possible that we will get back a window that we cannot read from, so we'll filter those out manually.
		int sharingState = [[entry objectForKey:(id)kCGWindowSharingState] intValue];
		if(sharingState != kCGWindowSharingNone)
		{
			NSString *appname = [entry objectForKey:(id)kCGWindowOwnerName];
			if ([appname rangeOfString:stringFromArgv].location != NSNotFound ){
				found = YES;
				CGWindowID windowID = [[entry objectForKey:(id)kCGWindowNumber] unsignedIntValue];
				
				/* bounds
				 CGRect bounds;
				 CGRectMakeWithDictionaryRepresentation((CFDictionaryRef)[entry objectForKey:(id)kCGWindowBounds], &bounds);
				 bounds = CGRectNull;
				 */
				
				/* options
				 uint32_t imageOptions;
				 //imageOptions = kCGWindowImageDefault;
				 //imageOptions = imageOptions | kCGWindowImageBoundsIgnoreFraming;
				 //imageOptions = ChangeBits(imageOptions, kCGWindowImageBoundsIgnoreFraming, [imageFramingEffects intValue] == NSOnState);
				 //imageOptions = ChangeBits(imageOptions, kCGWindowImageShouldBeOpaque, [imageOpaqueImage intValue] == NSOnState);
				 //imageOptions = ChangeBits(imageOptions, kCGWindowImageOnlyShadows, [imageShadowsOnly intValue] == NSOnState);
				 */
				CGImageRef windowImage = CGWindowListCreateImage(CGRectNull, kCGWindowListOptionIncludingWindow, windowID, kCGWindowImageDefault);
				// Create a bitmap rep from the image...
				NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithCGImage:windowImage];
				
				// save image
				
				data = [bitmapRep representationUsingType:NSPNGFileType properties:nil];
				[data writeToFile:@"/Users/yene/file.png" atomically:NO];
				
				[bitmapRep release];
				CGImageRelease(windowImage);	
				
				// break the loop
				break;
			}
		}
	}
	
	if (!found) {
		return 0;
	}
	
	[windowList release];
	
	// upload image
	//creating the url request
	NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://imagebanana.com/"]];
	//adding header information
	[urlRequest setHTTPMethod:@"POST"];
	
	NSString *stringBoundary = [NSString stringWithString:@"0xKhTmLbOuNdArY"];
    [urlRequest setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", stringBoundary] forHTTPHeaderField:@"Content-Type"];
	
	
	//setting up the body:
	NSMutableData *postBody = [NSMutableData dataWithCapacity:1]; //[NSMutableData dataWithCapacity:[data length] + 512];
	[postBody appendData:[[NSString stringWithFormat:@"--%@\r\n",stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithString:@"Content-Disposition: form-data; name=\"send\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithString:@"Hochladen!"] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithString:@"Content-Disposition: form-data; name=\"img\"; filename=\"file.png\"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithString:@"Content-Type: image/png\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
	//[postBody appendData:[NSData dataWithContentsOfFile:@"/test.txt"]];
	[postBody appendData:data];
	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[urlRequest setHTTPBody:postBody];
	
	
    NSData *answer = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:nil error:nil];
	
	if (!answer) {
		NSLog(@"fail");
	} else {
		// image url
		NSString *answerString = [NSString stringWithCString:[answer bytes] encoding:NSASCIIStringEncoding];
		NSRange range1 = [answerString rangeOfString:@"http://www.imagebanana.com/][IMG]http://www.imagebanana.com/img/"];
		NSRange range2 = NSMakeRange(range1.location, [answerString length]-range1.location); // such bereich
		range2 = [answerString rangeOfString:@"file.png" options:NSCaseInsensitiveSearch range:range2];
		range1.location = range1.location +33;
		NSRange range3 = NSMakeRange(range1.location, (range2.location+range2.length)-range1.location);
		NSString *url = [answerString substringWithRange:range3];
		
		// short url
		NSString *apiEndpoint = [NSString stringWithFormat:@"http://api.tr.im/v1/trim_simple?url=%@",url];
		NSString *shortURL = [NSString stringWithContentsOfURL:[NSURL URLWithString:apiEndpoint]
													  encoding:NSASCIIStringEncoding
														 error:nil];
		//NSLog(@"Long: %@ - Short: %@",url,shortURL);
		printf( "%s\n", [shortURL UTF8String] );
		//[answer writeToFile:@"/Users/yene/answer.html" atomically:NO];
	}

	
    [pool drain];
    return 0;
}
