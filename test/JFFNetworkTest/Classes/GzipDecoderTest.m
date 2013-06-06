@interface GzipDecoderTest : GHTestCase
@end


@implementation GzipDecoderTest

-(void)testErrorParameterIsRequired
{
   NSData*   gzip_data_  = [ JNTestBundleManager loadZipFileNamed : @"1" ];

   JNGzipDecoder* decoder_ = [ [ JNGzipDecoder alloc ] initWithContentLength: 100500 ];

   GHAssertThrows
   (
        [ decoder_ decodeData: gzip_data_
                        error: NULL ]
      , @"NULL error should produce assert"
   );
}

-(void)testNilDataProducesNilResult
{
    NSError* error_ = nil;

   JNGzipDecoder* decoder_ = [ [ JNGzipDecoder alloc ] initWithContentLength: 100500 ];
    NSData* received_data_ = [ decoder_ decodeData: nil
                                            error: &error_ ];

    GHAssertNil( received_data_, @"Nil output expected"    );
    GHAssertNil( error_        , @"No errors are expected" );
}

-(void)testGzipFromBackEndExtractedCorrectly
{
    NSError* error_ = nil;

    NSData*   gzip_data_ = [ JNTestBundleManager loadZipFileNamed : @"1" ];
    NSString* expected_  = [ JNTestBundleManager loadTextFileNamed: @"1" ];

   JNGzipDecoder* decoder_ = [ [ JNGzipDecoder alloc ] initWithContentLength: 1 ];
    NSData* received_data_ = [ decoder_ decodeData: gzip_data_
                                             error: &error_ ];
    GHAssertNil( error_, @"Unexpected decode error - %@", error_ );

   NSString* received_ = [ [ NSString alloc ] initWithData: received_data_
                                                    encoding: NSUTF8StringEncoding ];

    GHAssertTrue( [ received_ isEqualToString: expected_ ], @"Wrong decoding result" );
}

-(void)testBadDataProducesCorrectError
{
   NSError*       error_         = nil;
   NSData*        gzip_data_     = nil;
   NSData*        received_data_ = nil;
   JNGzipDecoder* decoder_ = nil;

   {
      //compressed with zip instead of gzip
      gzip_data_  = [ JNTestBundleManager loadZipFileNamed : @"1.1" ];
      decoder_ = [ [ JNGzipDecoder alloc ] initWithContentLength: [ gzip_data_ length ] ];
       
       
      received_data_ = [ decoder_ decodeData: gzip_data_
                                       error: &error_ ];

      GHAssertNil( received_data_, @"nil data in error Expected" );

      GHAssertTrue( [ error_.domain isEqualToString: kGzipErrorDomain ], @"Unexpected error domain" );
      GHAssertTrue( error_.code == Z_DATA_ERROR, @"Unexpected error code" );
   }

   {
      //compressed with zip instead of gzip
      gzip_data_  = [ JNTestBundleManager loadZipFileNamed : @"1-Incomplete" ];
      decoder_ = [ [ JNGzipDecoder alloc ] initWithContentLength: [ gzip_data_ length ] ];
       
      received_data_ = [ decoder_ decodeData: gzip_data_
                                       error: &error_ ];

      GHAssertNotNil( received_data_, @"nil data in error Expected" );
      GHAssertNil( error_, @"No error expected since on-the-fly unpacking was introduced " );
   }   
}

@end
