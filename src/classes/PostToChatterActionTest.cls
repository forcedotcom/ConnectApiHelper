@IsTest(SeeAllData=true)
public class PostToChatterActionTest {

    /**
        When testing ConnectApi the test class has to have SeeAllData=true
    */
    @IsTest(SeeAllData=true)
    static void testPostToChatterBatch(){
        String hashtag = 'Yolo';
        String text1 = ': ';
        String link = 'http://salesforce.com';
        String text2 = ', {005} ';
        String mentionId = UserInfo.getUserId();
        String entityId = [SELECT Id FROM Account LIMIT 1].Id;
        String text3 = ' test, ';
        String text4 = '.';
        String text = '#' + hashtag + text1 + link + text2 + '{' + mentionId + '}' + text3 + '{' + entityId + '}' + text4;
      
        List<PostToChatterAction.ChatterPost> chatterPosts = new List<PostToChatterAction.ChatterPost>();
        for(Integer i = 0; i < 200; i++){
            PostToChatterAction.ChatterPost cp = new PostToChatterAction.ChatterPost();
            cp.communityId = null;
            cp.subjectId = UserInfo.getUserId();
            cp.message = text;
            chatterPosts.add(cp);
        }

        List<PostToChatterAction.ChatterPostResult> results = PostToChatterAction.postToChatter(chatterPosts);
        System.assertEquals(200, results.size());

        for(PostToChatterAction.ChatterPostResult cpResult : results){
            System.assertEquals(true, cpResult.isSuccess);
        }
    }
}