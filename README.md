ConnectApiHelper
================

<a href="https://githubsfdeploy.herokuapp.com?owner=smukov&repo=ConnectApiHelper&ref=master">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png">
</a>

`ConnectApiHelper` is an Apex class that makes it easier to do common operations with the classes in the [ConnectApi namespace](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_classes_connect_api.htm). It includes convenience methods to:

* Post Chatter @-mentions with Apex code.
* Post links to Records with Apex code. 
* Post rich text and inline images with Apex code.
* Take a feed item or comment body and return an input body that matches it (useful for either editing or re-posting).
* Post a batch of up to 500 feed elements for the cost of one DML statement.

This repo also contains `PostToChatterAction` class which can be invoked from Process Builder and Flow to post a Chatter Post easily.

Easier @-mentions
-----------------
If you want to mention someone in a post that says: *Hey there @Jane Doe, how are you?*, you can do it in one line like this:

    ConnectApi.FeedItem fi = (ConnectApi.FeedItem) ConnectApiHelper.postFeedItemWithMentions(Network.getNetworkId(), 'me', 'Hey there {005D00000015tjz}, how are you?');

... instead of this:

    ConnectApi.MessageBodyInput messageInput = new ConnectApi.MessageBodyInput();
    messageInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();

    ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
    textSegment.text = 'Hey there ';
    messageInput.messageSegments.add(textSegment);

    ConnectApi.MentionSegmentInput mentionSegment = new ConnectApi.MentionSegmentInput();
    mentionSegment.id = '005D00000015tjz'; // The ID of the user to mention.
    messageInput.messageSegments.add(mentionSegment);

    textSegment = new ConnectApi.TextSegmentInput();
    textSegment.text = ', how are you?';
    messageInput.messageSegments.add(textSegment);

    ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
    input.body = messageInput;
    input.subjectId = 'me';

    ConnectApi.FeedItem fi = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), input);

Streamlined rich text and inline images
---------------------------------------
If you want to add rich text or inline images in your post, one line will do it:

    ConnectApi.FeedItem fi = ConnectApiHelper.postFeedItemWithRichText(Network.getNetworkId(),
    'me', 'Have you seen this <b>gorgeous</b> view? {img:069x00000000D7m:View of the Space Needle from our office.}');

... instead of this:

    ConnectApi.MessageBodyInput messageInput = new ConnectApi.MessageBodyInput();
    messageInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();

    ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
    textSegment.text = 'Have you seen this ';
    messageInput.messageSegments.add(textSegment);

    ConnectApi.MarkupBeginSegmentInput markupBeginSegment = new ConnectApi.MarkupBeginSegmentInput();
    markupBeginSegment.markupType = ConnectApi.MarkupType.Bold;
    messageInput.messageSegments.add(markupBeginSegment);

    textSegment = new ConnectApi.TextSegmentInput();
    textSegment.text = 'gorgeous';
    messageInput.messageSegments.add(textSegment);

    ConnectApi.MarkupEndSegmentInput markupEndSegment = new ConnectApi.MarkupEndSegmentInput();
    markupEndSegment.markupType = ConnectApi.MarkupType.Bold;
    messageInput.messageSegments.add(markupEndSegment);

    textSegment = new ConnectApi.TextSegmentInput();
    textSegment.text = ' view? ';
    messageInput.messageSegments.add(textSegment);

    ConnectApi.InlineImageSegmentInput inlineImageSegment = new ConnectApi.InlineImageSegmentInput();
    inlineImageSegment.fileId = '069x00000000D7m';
    inlineImageSegment.altText = 'View of the Space Needle from our office.';
    messageInput.messageSegments.add(inlineImageSegment);

    ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
    input.body = messageInput;
    input.subjectId = 'me';

    ConnectApi.FeedItem fi = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), input);

Installation
------------

For API version 43.0 and above you can use the **Deploy to Salesforce** button at the top, or you can manually copy the classes from the `src/classes` directory to your sandbox. This is the only version that allows mentioning (linking) records that are not of type User or Group. This is also the only version that contain the `PostToChatterAction` class for posting to chatter from Process Builder or Flow.

For @-mentions, the methods to use are `ConnectApiHelper.postFeedItemWithMentions` and `ConnectApiHelper.postCommentWithMentions` and the parameters and formatting syntax are described in the method comments. To include rich text and inline images as well (starting in version 35.0), the method to use is `ConnectApiHelper.postFeedItemWithRichText`.  You can also refer to the `ConnectApiHelperTest` class for more examples.

To post a batch of up to 500 feed elements for the cost of one DML statement (starting in version 43.0) use the `ConnectApiHelper.createFeedItemWithMentions` to create the elements in memory, and then pass them to `ConnectApiHelper.postFeedItemBatch` method. You can see the example of this in `ConnectApiHelperTest.testBatchPosting` test method, and also in the `PostToChatterAction.postToChatter` invocable method.

For creating input bodies from output bodies, the methods are `ConnectApiHelper.createFeedItemInputFromBody` and `ConnectApiHelper.createCommentInputFromBody`.

If you need to use API version 31.0 or earlier, be sure to use the ConnectApiHelper class that's contained in the `OldApiVersions/v31AndEarlier` directory.

If you need to use API versions 32.0, 33.0, or 34.0, use the one that's in the `OldApiVersions/v32-v34` directory. These API versions do not support rich text segments.

If you need to use API version 35.0, use the one that's in the `OldApiVersions/v35` directory.

If you need to use API versions 36.0 to 42.0, use the one that's in the `OldApiVersions/v36-v42` directory. These API versions do not support linking to all records and bulk posting.
