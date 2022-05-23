List<user> liusr = [SELECT Id,ProfileId FROM user WHERE Profile.name='BFG Standard User'];
List<user> listuser = new List<user>();
for(user u : liusr)
{
  user usr = new user();
  usr.Id= u.Id;
  usr.profileId='00e5b0000016wzV';
  listuser.add(usr);
}
Update listuser;
