ConnectApiHelper
================

`ConnectApiHelper` is an Apex class that makes it easier to do common operations with the classes in the [ConnectApi namespace](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_classes_connect_api.htm). It includes convenience methods to:

* Post Chatter @-mentions with Apex code.
* Post rich text, inline images, and record links with Apex code.
* Take a feed item or comment body and return an input body that matches it (useful for either editing or re-posting).

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

Streamlined rich text, inline images and record links
-----------------------------------------------------
If you want to add rich text, inline images, or record links in your post, one line will do it:

    ConnectApi.FeedItem fi = (ConnectApi.FeedItem) ConnectApiHelper.postFeedItemWithRichText(Network.getNetworkId(),
    'me', 'Have you seen this <b>gorgeous</b> view? {img:069x00000000D7m:View of the Space Needle from our office.} \nBy the way, please check {record:01t3E000002GCm9QAG}');

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

    textSegment = new ConnectApi.TextSegmentInput();
    textSegment.text = ' \nBy the way, please check ';
    messageInput.messageSegments.add(textSegment);

    ConnectApi.EntityLinkSegmentInput entityLinkSegment = new ConnectApi.EntityLinkSegmentInput();
    entityLinkSegment.entityId = '01t3E000002GCm9QAG';
    messageInput.messageSegments.add(entityLinkSegment);

    ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
    input.body = messageInput;
    input.subjectId = 'me';

    ConnectApi.FeedItem fi = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), input);

Installation
------------

Just copy the [ConnectApiHelper](force-app/main/default/classes/ConnectApiHelper.cls) and [ConnectApiHelperTest](force-app/main/default/classes/ConnectApiHelperTest.cls) classes to your Salesforce org. If you use [Salesforce DX](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_intro.htm), you can clone this repo and develop using your preferred IDE, source control system, and scratch orgs. 

Usage
-----

 For @-mentions, the methods to use are `ConnectApiHelper.postFeedItemWithMentions` and `ConnectApiHelper.postCommentWithMentions` and the parameters and formatting syntax are described in the method comments. To include rich text and inline images as well (starting in version 35.0), the method to use is `ConnectApiHelper.postFeedItemWithRichText`.  You can also refer to the `ConnectApiHelperTest` class for more examples.

For creating input bodies from output bodies, the methods are `ConnectApiHelper.createFeedItemInputFromBody` and `ConnectApiHelper.createCommentInputFromBody`.

Salesforce API Versions
-----------------------

If you need to use an earlier version of the Salesforce API, the current `ConnectApiHelper` class may not compile, because the methods being called may not be available in the earlier version. 

We've provided variants of `ConnectApiHelper` so that you can use it with earlier Salesforce API versions:

| API Version      | ConnectApiHelper location                 | Limitations                                |
|------------------|-------------------------------------------|--------------------------------------------|
| 43.0 and higher  | [default](force-app/main/default/classes) |                                            |
| 36.0-42.0        | [v36-v42](v36-v42)                        | Record links not supported                 |
| 35.0             | [v35](v35)                                | Same as above                              |
| 32.0-34.0        | [v32-v34](v32-v34)                        | Same as above, and rich text not supported |
| 31.0 and earlier | [v31AndEarlier](v31AndEarlier)            | Same as above                              |
