global class PostToChatterAction {
    
    @InvocableMethod(label='Post to Chatter')
    global static List<ChatterPostResult> postToChatter(List<ChatterPost> chatterMessages) 
    {      
        //Split Chatter Posts into their respective communities
        Map<String, List<ConnectApi.FeedItemInput>> communityToChatterPosts = new Map<String, List<ConnectApi.FeedItemInput>>();
        for(ChatterPost msg : chatterMessages)
        {								
            //Create a FeedItemInput from the Chatter Post message and Subject Id
            ConnectApi.FeedItemInput feedItem = 
                (ConnectApi.FeedItemInput) ConnectApiHelper.createFeedItemWithMentions(msg.subjectId, msg.message);
            
            if(communityToChatterPosts.containsKey(msg.communityId)){ communityToChatterPosts.get(msg.communityId).add(feedItem); }
            else { communityToChatterPosts.put(msg.communityId, new ConnectApi.FeedItemInput[]{ feedItem }); }
        }
        
        //Post the Chatter Messages to their respective communities and return the results of those postings
        List<ConnectApi.BatchResult> batchResults = new List<ConnectApi.BatchResult>();
        for(String communityId : communityToChatterPosts.keySet()){
            batchResults.addAll(
                ConnectApiHelper.postFeedItemBatch(
                    communityId, 
                    communityToChatterPosts.get(communityId)));
        }
        
        //return the results of the postings
        //NOTE: the results might get scrambled if the postings are being sent to different community Ids
        //(i.e. the results won't follow the same order as inputted chatterMessages in that case)
        List<ChatterPostResult> results = new List<ChatterPostResult>();
        for(ConnectApi.BatchResult r : batchResults){
            ChatterPostResult cpr = new ChatterPostResult();
            cpr.isSuccess = r.isSuccess();
            cpr.errorMessage = r.getErrorMessage();
            results.add(cpr);
        }
        return results;
    }
    
    global class ChatterPost {
        @InvocableVariable(label='Community Id' description='Use either the ID of a community, "internal", or null.')
        global String communityId;
        
        @InvocableVariable(required=true label='Subject Id' description='The parent of the post. Can be a user ID, a group ID, or a record ID.')
        global Id subjectId;

        @InvocableVariable(required=true label='Message' description='Chatter Post message.')
        global String message;
    }

    global class ChatterPostResult {
        @InvocableVariable(label='Is Success?' description='TRUE if chatter post has been posted successfully, otherwise FALSE.')
        global Boolean isSuccess;

        @InvocableVariable(label='Error Message' description='Reason why the posting failed.')
        global String errorMessage;
    }
}