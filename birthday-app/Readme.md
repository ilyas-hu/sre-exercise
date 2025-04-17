## Manual PostgreSQL Permissions Grant for IAM User

**Purpose:** We need to grant the IAM user permission on the created database in postgress to be able to run migrations. 

Note De the following steps after terraform completes creating the infrastructure and database,

**Steps:**

1.  Connect to the created Database as postgress Admin, using Console or Glcoud, Reset the super user password if needed. make sure the user name is correct as created by terraform.


3.  **Grant Required Permissions:**
        ```sql
        -- Grant the ability to use the public schema
        GRANT USAGE ON SCHEMA public TO "hello-app-user-sqlsa@sre-exercise.iam";

        -- Grant the ability to create tables in the public schema
        GRANT CREATE ON SCHEMA public TO "hello-app-user-sqlsa@sre-exercise.iam";

        -- Grant standard data manipulation permissions
        ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO "hello-app-user-sqlsa@sre-exercise.iam";
        ```

